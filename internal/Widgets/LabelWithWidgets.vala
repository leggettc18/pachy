public class Pachy.Internal.Widgets.LabelWithWidgets: Gtk.Widget {
    private const string OBJECT_REPLACEMENT_CHARACTER = "\xEF\xBF\xBC";
    private Gtk.Label label;
    private Gtk.Widget[] widgets = {};
    private int[] widget_heights = {};
    private int[] widget_widths = {};

    public signal bool activate_link (string uri);

    public int lines {
        get { return label.lines; }
        set { label.lines = value; }
    }

    public bool single_line_mode {
        get { return label.single_line_mode; }
        set { label.single_line_mode = value; }
    }

    public float xalign {
        get { return label.xalign; }
        set { label.xalign = value; }
    }

    public bool selectable {
        get { return label.selectable; }
        set { label.selectable = value; }
    }

    public Gtk.Justification justify {
        get { return label.justify; }
        set { label.justify = value; }
    }

    private string _placeholder = "<widget>";
    public string placeholder {
        get { return _placeholder; }
        set {
            _placeholder = value;
            update_label ();
        }
    }

    private string _text = "";
    public string text {
        get { return _text; }
        set {
            _text = value;
            update_label ();
            label.notify_property ("label");
        }
    }

    private bool _ellipsize = false;
    public bool ellipsize {
        get { return _ellipsize; }
        set {
            _ellipsize = value;
            update_label ();
        }
    }

    private bool _use_markup = false;
    public bool use_markup {
        get { return _use_markup; }
        set {
            _use_markup = value;
            label.use_markup = _use_markup;
        }
    }

    construct {
        label = new Gtk.Label ("") {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            xalign = 0.0f,
            valign = Gtk.Align.START,
        };
        label.set_parent (this);
        label.activate_link.connect ((url) => activate_link (url));
    }

    ~LabelWithWidgets () {
        label.unparent ();
        foreach (var child in widgets) {
            child.unparent ();
        }
    }

    public void set_children (Gtk.Widget[] t_widgets) {
        foreach (var child in widgets) {
            child.unparent ();
            child.destroy ();
        }

        widgets = {};
        widget_widths = {};
        widget_heights = {};

        foreach (unowned Gtk.Widget widget in t_widgets) {
            append_child (widget);
        }
    }

    public void append_child (Gtk.Widget child) {
        widgets += child;
        widget_widths += 0;
        widget_heights += 0;

        child.set_parent (this);
        invalidate_child_widgets ();
    }

    private void invalidate_child_widgets () {
        for (var i = 0; i < widget_widths.length; i++) {
            widget_widths[i] = 0;
            widget_heights[i] = 0;
        }
        this.allocate_shapes ();
        this.queue_resize ();
    }

    private void allocate_shapes () {
        var child_size_changed = false;

        if (text == "") {
            return;
        }

        if (widgets.length == 0) {
            label.attributes = null;
            return;
        }

        for (var i = 0; i < widgets.length; i++) {
            Gtk.Widget child = widgets[i];
            Gtk.Requisition size;
            Gtk.Requisition natural_size;
            child.get_preferred_size (out size, out natural_size);
            int width = natural_size.width;
            int height = natural_size.height;
            int old_width = widget_widths[i];
            int old_height = widget_heights[i];
            if (old_width > 0 || old_height > 0) {
                if (old_width != width || old_height != height) {
                    widget_widths[i] = width;
                    widget_heights[i] = height;
                    child_size_changed = true;
                }
            } else {
                widget_widths[i] = width;
                widget_heights[i] = height;
                child_size_changed = true;
            }
        }

        if (!child_size_changed) {
            return;
        }

        var attrs = new Pango.AttrList ();
        int index = 0;

        for (var i = 0; i < widget_widths.length; i++) {
            index = label.get_text ().index_of (OBJECT_REPLACEMENT_CHARACTER, index);
            if (index < 0) {
                break;
            }
            var width = widget_widths[i];
            var height = widget_heights[i];
            var logical_rect = Pango.Rectangle () {
                x = 0,
                y = - (height - (height / 4)) * Pango.SCALE,
                width = width * Pango.SCALE,
                height = height * Pango.SCALE,
            };
            var shape = Pango.AttrShape.new (logical_rect, logical_rect);
            shape.start_index = index;
            shape.end_index = index + OBJECT_REPLACEMENT_CHARACTER.length;
            attrs.insert (shape.copy ());
            index = index + OBJECT_REPLACEMENT_CHARACTER.length;
        }
        label.attributes = attrs;
    }

    private void update_label () {
        var old_label = label.label;
        var old_ellipsize = label.ellipsize == Pango.EllipsizeMode.END;
        var new_ellipsize = this.ellipsize;
        var new_label = _text.replace (placeholder, OBJECT_REPLACEMENT_CHARACTER);

        if (new_ellipsize) {
            int pos = new_label.index_of_char ('\n');
            if (pos >= 0) {
                new_label = new_label.substring (0, pos) + "…";
            }
        }

        if (old_ellipsize != new_ellipsize || old_label != new_label) {
            if (new_ellipsize) {
                label.wrap = false;
                label.ellipsize = Pango.EllipsizeMode.END;
            } else {
                label.wrap = true;
                label.wrap_mode = Pango.WrapMode.WORD_CHAR;
                if (lines == 100 && widgets.length > 100) {
                    lines = widgets.length;
                }
                label.ellipsize = lines < 100 ? Pango.EllipsizeMode.NONE : Pango.EllipsizeMode.END;
            }
            _text = new_label;
            label.label = _text;
            invalidate_child_widgets ();
        }
    }

    public override void size_allocate (int width, int height, int baseline) {
        label.allocate (width, height, baseline, null);
        this.allocate_children ();
    }

    private void allocate_children () {
        var run_iter = label.get_layout ().get_iter ();
        int i = 0;
        while (true) {
            var run = run_iter.get_run_readonly ();
            if (run != null) {
                var extra_attrs = run.item.analysis.extra_attrs.copy ();
                bool has_shape_attr = false;
                foreach (var attr in extra_attrs) {
                    if (((Pango.Attribute) attr).as_shape () != null) {
                        has_shape_attr = true;
                        break;
                    }
                }

                if (has_shape_attr) {
                    if (i < widgets.length) {
                        var widget = widgets[i];
                        var width = widget_widths[i];
                        var height = widget_heights[i];

                        Pango.Rectangle logical_rect;
                        run_iter.get_run_extents (null, out logical_rect);

                        int offset_x;
                        int offset_y;
                        label.get_layout_offsets (out offset_x, out offset_y);

                        var allocation = Gtk.Allocation () {
                            x = pango_pixels (logical_rect.x) + offset_x,
                            y = pango_pixels (logical_rect.y) + offset_y,
                            height = height,
                            width = width,
                        };
                        widget.allocate_size (allocation, -1);
                        i++;
                    } else {
                        break;
                    }
                }
            }
            if (!run_iter.next_run ()) {
                break;
            }
        }
    }

    private int pango_pixels (int d) {
        return (d + 512) >> 10;
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return label.get_request_mode ();
    }

    public override void measure (
        Gtk.Orientation orientation,
        int for_size,
        out int minimum,
        out int natural,
        out int minimum_baseline,
        out int natural_baseline
    ) {
        this.allocate_shapes ();
        this.label.measure (
            orientation,
            for_size,
            out minimum,
            out natural,
            out minimum_baseline,
            out natural_baseline
        );
    }
}
