public class Pachy.Widgets.AccountRow : Gtk.ListBoxRow {
    private Services.Accounts.InstanceAccount? _account = null;
    public Services.Accounts.InstanceAccount? account {
        get { return _account; }
        set {
            if (_account == null && value != null) {
                label_box.append (subtitle_label);
            }
            _account = value;
        }
    }
    public string title {
        get { return title_label.content; }
        set { title_label.content = value; }
    }
    public string subtitle {
        get { return subtitle_label.label; }
        set { subtitle_label.label = value; }
    }

    private Avatar avatar;
    private Gtk.Button forget;
    private EmojiLabel title_label;
    private Gtk.Label subtitle_label;
    private Gtk.Box box;
    private Gtk.Box label_box;

    private Binding switcher_display_name;
    private Binding switcher_emojis;
    private Binding switcher_handle;
    private Binding switcher_tooltip;
    private Binding switcher_avatar;

    public AccountRow (Services.Accounts.InstanceAccount? _account) {
        if (account != null) {
            switcher_display_name.unbind ();
            switcher_handle.unbind ();
            switcher_tooltip.unbind ();
            switcher_avatar.unbind ();
        }
        account = _account;
        if (account != null) {
            switcher_display_name = this.account.bind_property (
                "display-name", this, "title", BindingFlags.SYNC_CREATE
            );
            switcher_emojis = this.account.bind_property (
                "emojis-map", title_label, "instance-emojis", BindingFlags.SYNC_CREATE
            );
            switcher_handle = this.account.bind_property ("handle", this, "subtitle", BindingFlags.SYNC_CREATE);
            switcher_tooltip = this.account.bind_property ("handle", this, "tooltip-text", BindingFlags.SYNC_CREATE);
            switcher_avatar = this.account.bind_property ("avatar", avatar, "avatar-url", BindingFlags.SYNC_CREATE);
        } else {
            title = _("Add Account");
            avatar.account = null;
            selectable = false;
            forget.hide ();
        }
    }

    construct {
        avatar = new Avatar () {
            size = 32,
        };
        avatar.clicked.connect (on_open);
        forget = new Gtk.Button.from_icon_name ("user-trash-symbolic");
        forget.add_css_class (Granite.STYLE_CLASS_CIRCULAR);
        forget.clicked.connect (on_forget);
        title_label = new EmojiLabel (_("Add Account")) {
            ellipsize = true,
        };
        subtitle_label = new Gtk.Label ("") {
            ellipsize = Pango.EllipsizeMode.END,
        };
        subtitle_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
            valign = Gtk.Align.CENTER,
            hexpand = true,
        };
        label_box.append (title_label);
        if (this.account != null) {
            label_box.append (subtitle_label);
        }
        box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
        };
        box.append (avatar);
        box.append (label_box);
        box.append (forget);
        child = box;
    }

    void on_open () {
        if (account != null) {
            account.resolve_open (accounts.active);
        }
    }

    void on_forget () {
        // TODO: confirmation dialog and delete account
    }
}
