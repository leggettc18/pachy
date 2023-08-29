public class Pachy.Views.Sidebar : Gtk.Box, API.AccountHolder {
    private Gtk.ToggleButton accounts_button;
    private Gtk.HeaderBar headerbar;
    private Gtk.Stack mode;
    private Gtk.Box items_mode_box;
    private Gtk.Button account_button;
    private Gtk.Box account_button_box;
    private Gtk.Box avatar_title_box;
    private Gtk.ListBox items;
    private Gtk.ListBox saved_accounts;
    private Widgets.Avatar avatar;
    private Pachy.Widgets.EmojiLabel title;
    private Gtk.Label subtitle;
    private Gtk.ScrolledWindow scrolled;
    private Gtk.Viewport viewport;

    protected Services.Accounts.InstanceAccount? account { get; set; default = null; }
    protected ListStore app_items;
    protected Gtk.SliceListModel account_items;
    protected Gtk.FlattenListModel item_model;

    public static API.Place keyboard_shortcuts = new API.Place () {
        icon = "preferences-desktop-keyboard-symbolic",
        title = _("Keyboard Shortcuts"),
        selectable = false,
        open_func = null,
    };

    public static API.Place preferences = new API.Place () {
        icon = "preferences-system-symbolic",
        title = _("Preferences"),
        selectable = false,
        separated = true,
        open_func = null,
    };

    public static API.Place about = new API.Place () {
        icon = "dialog-information-symbolic",
        title = _("About"),
        selectable = false,
        open_func = null,
    };

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        spacing = 0;
        width_request = 200;
        headerbar = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label (""),
        };
        // TODO: Compose Button
        accounts_button = new Gtk.ToggleButton () {
            icon_name = "avatar-default-symbolic",
            tooltip_text = _("Switch Account"),
        };
        accounts_button.toggled.connect (on_mode_changed);
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        headerbar.pack_start (new Gtk.WindowControls (Gtk.PackType.START));
        headerbar.pack_end (accounts_button);
        append (headerbar);

        mode = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE,
        };
        viewport = new Gtk.Viewport (null, null) {
            child = mode,
        };
        scrolled = new Gtk.ScrolledWindow () {
            vexpand = true,
            child = viewport,
        };
        append (scrolled);

        items_mode_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        account_button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = margin_end = margin_top = margin_bottom = 12,
        };
        items_mode_box.append (account_button_box);
        avatar = new Widgets.Avatar ();
        account_button_box.append (avatar);
        avatar_title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 4) {
            valign = Gtk.Align.CENTER,
            hexpand = true,
        };
        account_button_box.append (avatar_title_box);

        account_button = new Gtk.Button ();
        account_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        account_button.add_css_class ("no-border-radius");
        account_button.child = account_button_box;

        title = new Widgets.EmojiLabel ();
        avatar_title_box.append (title);
        subtitle = new Gtk.Label ("Handle") {
            xalign = 0,
            lines = 0,
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
        };
        subtitle.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        subtitle.add_css_class ("body");
        avatar_title_box.append (subtitle);

        items_mode_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        items = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.SINGLE,
        };
        items.row_activated.connect (on_item_activated);
        items.add_css_class (Granite.STYLE_CLASS_SIDEBAR);
        items_mode_box.append (items);

        mode.add_titled (items_mode_box, "items", "items");

        saved_accounts = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.SINGLE,
        };
        saved_accounts.row_activated.connect (on_account_activated);
        saved_accounts.add_css_class (Granite.STYLE_CLASS_SIDEBAR);

        mode.add_titled (saved_accounts, "saved_accounts", "saved_accounts");

        app_items = new ListStore (typeof (API.Place));
        app_items.append (preferences);
        app_items.append (keyboard_shortcuts);
        app_items.append (about);

        account_items = new Gtk.SliceListModel (null, 0, 15);

        var models = new ListStore (typeof (Object));
        models.append (account_items);
        models.append (app_items);
        item_model = new Gtk.FlattenListModel (models);

        items.bind_model (item_model, on_item_create);
        items.set_header_func (on_item_header_update);
        saved_accounts.set_header_func (on_account_header_update);

        construct_account_holder ();
    }

    protected virtual void on_accounts_changed (Gee.ArrayList<Services.Accounts.InstanceAccount> accounts) {
        var w = saved_accounts.get_first_child ();
        while (w != null) {
            saved_accounts.remove (w);
            w = saved_accounts.get_first_child ();
        }

        accounts.foreach (acc => {
            saved_accounts.append (new Widgets.AccountRow (acc));
            return true;
        });

        var new_acc_row = new Widgets.AccountRow (null);
        saved_accounts.append (new_acc_row);
    }

    public void set_sidebar_selected_item (int index) {
        if (items != null) {
            items.select_row (items.get_row_at_index (index));
        }
    }

    private Binding sidebar_handle_short;
    private Binding sidebar_avatar;
    private Binding sidebar_display_name;

    protected virtual void on_account_changed (Services.Accounts.InstanceAccount? account) {
        if (this.account != null) {
            sidebar_handle_short.unbind ();
            sidebar_avatar.unbind ();
            sidebar_display_name.unbind ();
        }

        if (app?.main_window != null) {
            app.main_window.go_back_to_start ();
        }

        this.account = account;
        accounts_button.active = false;

        if (account != null) {
            sidebar_handle_short = this.account.bind_property (
                "handle_short", subtitle, "label", BindingFlags.SYNC_CREATE
            );
            sidebar_avatar = this.account.bind_property ("avatar", avatar, "avatar-url", BindingFlags.SYNC_CREATE);
            debug ("Display Name: %s", account.display_name);
            sidebar_display_name = this.account.bind_property (
                "display-name",
                title,
                "content",
                BindingFlags.SYNC_CREATE,
                (b, src, ref target) => {
                    target.set_string (src.get_string ());
                    return true;
                }
            );
            account_items.model = account.known_places;
        } else {
            saved_accounts.unselect_all ();
            title.content = _("Anonymous");
            subtitle.label = _("No account selected");
            avatar.account = null;
            account_items.model = null;
        }
    }

    void on_mode_changed () {
        mode.visible_child_name = accounts_button.active ? "saved_accounts" : "items";
    }

    void on_open () {
        if (account == null) {
            return;
        }
        account.open ();
    }

    Gtk.Widget on_item_create (Object obj) {
        return new Widgets.ItemRow (obj as API.Place);
    }

    void on_item_activated (Gtk.ListBoxRow _row) {
        var row = _row as Widgets.ItemRow;
        if (row.place.open_func != null) {
            row.place.open_func (app.main_window);
        }
    }

    void on_item_header_update (Gtk.ListBoxRow _row, Gtk.ListBoxRow? _before) {
        var row = _row as Widgets.ItemRow;
        var before = _before as Widgets.ItemRow;

        row.set_header (null);

        if (row.place.separated && before != null && !before.place.separated) {
            row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        }
    }

    void on_account_header_update (Gtk.ListBoxRow _row, Gtk.ListBoxRow? _before) {
        var row = _row as Widgets.AccountRow;
        row.set_header (null);
        if (row.account == null && _before != null) {
            row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        }
    }

    void on_account_activated (Gtk.ListBoxRow _row) {
        var row = _row as Widgets.AccountRow;
        if (row.account != null) {
            accounts.activate (row.account);
        } else {
            new Dialogs.NewAccount ().present ();
        }
    }
}
