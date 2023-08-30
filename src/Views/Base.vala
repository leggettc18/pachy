public class Pachy.Views.Base : Gtk.Box {
    public const string STATUS_EMPTY = _("Nothing to see here");

    public string? icon { get; set; default = null; }
    public string label { get; set; default = ""; }
    public bool needs_attention { get; set; default = false; }
    public bool is_main { get; set; default = false; }
    public bool allow_nesting { get; set; default = false; }
    public bool is_sidebar_item { get; set; default = false; }
    public int badge_number { get; set; default = 0; }

    protected SimpleActionGroup actions { get; set; default = new SimpleActionGroup (); }

    private bool _current = false;
    public bool current {
        get { return _current; }
        set {
            _current = value;
            if (value) {
                on_shown ();
            } else {
                on_hidden ();
            }
        }
    }

    protected Gtk.HeaderBar header;
    protected Gtk.Button back_button;
    protected Gtk.ScrolledWindow scrolled;
    protected Gtk.ScrolledWindow status_scrolled;
    protected Gtk.Overlay scrolled_overlay;
    protected Gtk.Button scroll_to_top;
    protected Gtk.Stack states;
    protected Gtk.Button status_button;
    protected Gtk.Box content_box;
    private Gtk.Stack status_stack;
    private Gtk.Label status_title_label;
    private Gtk.Label status_message_label;
    private Gtk.Spinner status_spinner;
    private Gtk.Viewport viewport;
    private Gtk.Box status;
    private Gtk.Image status_image;
    private Gtk.Box message_box;

    public class StatusMessage : Object {
        public string title = STATUS_EMPTY;
        public string? message = null;
        public bool loading = false;
    }

    private StatusMessage? _base_status = null;
    public StatusMessage base_status {
        get { return _base_status; }
        set {
            if (value == null) {
                states.visible_child_name = "content";
                status_spinner.spinning = false;
            } else {
                states.visible_child_name = "status";
                if (value.loading) {
                    status_stack.visible_child_name = "spinner";
                    status_spinner.spinning = true;
                } else {
                    status_stack.visible_child_name = "message";
                    status_spinner.spinning = false;

                    status_title_label.label = value.title;
                    if (value.message != null) {
                        status_message_label.label = value.message;
                    }
                }
            }
            _base_status = value;
        }
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        width_request = 360;
        add_css_class (Granite.STYLE_CLASS_VIEW);

        build_actions ();
        build_header ();

        append (header);

        // Back Button
        back_button = new Gtk.Button.with_label (_("Back"));
        back_button.clicked.connect (on_close);
        back_button.add_css_class (Granite.STYLE_CLASS_BACK_BUTTON);

        // Main View
        scrolled_overlay = new Gtk.Overlay ();
        scroll_to_top = new Gtk.Button.from_icon_name ("go-top-symbolic") {
            valign = Gtk.Align.END,
            halign = Gtk.Align.END,
            margin_end = margin_bottom = 16,
            visible = false,
        };
        scroll_to_top.add_css_class (Granite.STYLE_CLASS_CIRCULAR);
        scroll_to_top.add_css_class (Granite.STYLE_CLASS_OSD);
        scrolled_overlay.add_overlay (scroll_to_top);
        states = new Gtk.Stack () {
            vexpand = true,
            vhomogeneous = false,
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            interpolate_size = true,
        };
        scrolled_overlay.child = states;

        // Status Page
        viewport = new Gtk.Viewport (null, null);
        status_scrolled = new Gtk.ScrolledWindow () {
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = viewport,
        };
        status = new Gtk.Box (Gtk.Orientation.VERTICAL, 16) {
            valign = Gtk.Align.CENTER,
            margin_top = margin_bottom = 16,
        };
        status_image = new Gtk.Image.from_icon_name ("image-loading-symbolic") {
            pixel_size = 128,
            width_request = 128,
            height_request = 128,
        };
        status_image.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        status_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE,
        };
        message_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            valign = Gtk.Align.CENTER,
        };
        status_title_label = new Gtk.Label ("") {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            justify = Gtk.Justification.CENTER,
        };
        status_title_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);
        status_message_label = new Gtk.Label ("") {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            justify = Gtk.Justification.CENTER,
        };
        status_message_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);
        status_spinner = new Gtk.Spinner () {
            height_request = 32,
            valign = Gtk.Align.CENTER,
        };
        status_button = new Gtk.Button () {
            visible = false,
            halign = Gtk.Align.CENTER,
        };
        status_button.add_css_class ("pill");

        content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true,
            visible = true,
        };
        scrolled = new Gtk.ScrolledWindow () {
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = content_box,
        };

        message_box.append (status_title_label);
        message_box.append (status_message_label);
        status_stack.add_named (message_box, "message");
        status_stack.add_named (status_spinner, "spinner");
        status.append (status_image);
        status.append (status_stack);
        status.append (status_button);
        viewport.child = status;
        states.add_named (status_scrolled, "status");
        states.add_named (scrolled, "content");
        append (scrolled_overlay);

        status_button.label = _("Reload");
        base_status = new StatusMessage () { loading = true };

        scroll_to_top.clicked.connect (on_scroll_to_top);
    }

    ~Base () {
        message (@"Destroying base $label");
    }

    private void on_scroll_to_top () {
        scrolled.scroll_child (Gtk.ScrollType.START, false);
    }

    public virtual void scroll_page (bool up = false) {
        scrolled.scroll_child (up ? Gtk.ScrollType.PAGE_BACKWARD : Gtk.ScrollType.PAGE_FORWARD, false);
    }

    public override void dispose () {
        actions.dispose ();
        base.dispose ();
    }

    protected virtual void build_actions () {}

    protected virtual void build_header () {
        header = new Gtk.HeaderBar () {
            show_title_buttons = false,
        };
        header.add_css_class (Granite.STYLE_CLASS_FLAT);
        header.pack_end (new Gtk.WindowControls (Gtk.PackType.END));
    }

    public virtual void clear () {
        base_status = null;
    }

    public virtual void on_shown () {
        if (app != null && app.main_window != null) {
            app.main_window.insert_action_group ("view", actions);
        }
    }

    public virtual void on_hidden () {
        if (app != null && app.main_window != null) {
            app.main_window.insert_action_group ("view", null);
        }
    }

    public virtual void on_content_changed () {}

    public virtual void on_error (int32 code, string reason) {
        base_status = new StatusMessage () {
            title = _("An Error Occurred"),
            message = reason,
        };

        status_button.visible = true;
        status_button.sensitive = true;
    }

    private void on_close () {
        app.main_window.back ();
    }
}
