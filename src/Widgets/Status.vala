public class Pachy.Widgets.Status : Gtk.Widget {
    private API.Status? _bound_status = null;
    public API.Status? status {
        get { return _bound_status; }
        set {
            if (_bound_status != null) {
                warning ("Trying to rebind a Status Widget! This is not supposed to happen!");
            }
            _bound_status = value;
            if (_bound_status != null) {
                bind ();
            }
            if (context_menu == null) {
                create_actions ();
            }
        }
    }
    public API.Account? kind_instigator { get; set; default = null; }
    private Gtk.Button? quoted_status_btn { get; set; default = null; }
    public bool enable_thread_lines { get; set; default = false; }

    private bool _can_be_opened = false;
    public bool can_be_opened {
        get { return _can_be_opened; }
        set {
            _can_be_opened = value;
            if (value) {
                add_css_class ("activatable");
            } else {
                remove_css_class ("activatable");
            }
        }
    }

    private bool _is_quote = false;
    public bool is_quote {
        get { return _is_quote; }
        set {
            _is_quote = value;
            Gtk.Widget?[] widgets_to_toggle = {
                menu_button,
                emoji_reactions,
                actions,
                quoted_status_btn,
                prev_card,
            };

            foreach (var widget in widgets_to_toggle) {
                if (widget != null) {
                    widget.visible = !value;
                }
            }
        }
    }

    private string? _kind = null;
    public string kind {
        get { return _kind; }
        set {
            if (value != _kind) {
                _kind = value;
                change_kind ();
            }
        }
    }

    private bool _change_background_on_direct = true;
    public bool change_background_on_direct {
        get { return _change_background_on_direct; }
        set {
            _change_background_on_direct = value;
            if (!value) {
                remove_css_class ("direct");
            }
        }
    }

    // TODO: Compose SuccessCallback

    protected Gtk.Box status_box;
    protected Gtk.Box avatar_side;
    protected Gtk.Box title_box;
    protected Gtk.Box content_side;
    protected Gtk.FlowBox name_flowbox;
    public Gtk.MenuButton menu_button;

    protected Gtk.Image header_icon;
    protected RichLabel header_label;
    protected Gtk.Button header_button;
    public Gtk.Image thread_line_top;
    public Gtk.Image thread_line_bottom;

    public Avatar avatar;
    public Gtk.Overlay avatar_overlay;
    protected Gtk.Button name_button;
    protected RichLabel name_label;
    protected Gtk.Label handle_label;
    protected Gtk.Box indicators;
    protected Gtk.Label date_label;
    protected Gtk.Image pin_indicator;
    protected Gtk.Image edited_indicator;
    protected Gtk.Image visibility_indicator;

    public Gtk.Box content_column;
    protected Gtk.Stack spoiler_stack;
    protected Gtk.Box content_box;
    protected MarkupView content;
    protected Gtk.Button spoiler_button;
    protected Gtk.Label spoiler_label;
    protected Gtk.Label spoiler_label_rev;
    protected Gtk.Box spoiler_status_con;

    public ActionsRow actions { get; private set; }
    protected Gtk.PopoverMenu context_menu { get; set; }
    private const ActionEntry[] ACTION_ENTRIES = {
        {"copy-url", copy_url},
        {"open-in-browser", open_in_browser},
    };
    private SimpleActionGroup action_group;
    private SimpleAction edit_history_simple_action;
    private SimpleAction stats_simple_action;
    private SimpleAction toggle_pinned_simple_action;

    protected Gtk.Widget emoji_reactions;
    // TODO: emoji reactions

    construct {
        css_classes = { "ttl-post", "card-spacing", "card", "activatable" };
        layout_manager = new Gtk.BinLayout ();
        status_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 14) {
            margin_start = margin_end = margin_bottom = 18,
            margin_top = 15,
            hexpand = true,
        };
        avatar_side = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        header_icon = new Gtk.Image.from_icon_name ("oops") {
            visible = false,
            halign = Gtk.Align.END,
            icon_size = Gtk.IconSize.INHERIT,
        };
        thread_line_top = new Gtk.Image () {
            visible = false,
            width_request = 4,
            halign = Gtk.Align.CENTER,
            pixel_size = 4,
        };
        avatar_overlay = new Gtk.Overlay () {
            margin_top = 3,
        };
        avatar_overlay.add_css_class (Granite.STYLE_CLASS_FLAT);
        avatar = new Avatar () {
            size = 48,
            valign = Gtk.Align.START,
            visible = true,
        };
        thread_line_bottom = new Gtk.Image () {
            visible = false,
            width_request = 4,
            vexpand = true,
            halign = Gtk.Align.CENTER,
            pixel_size = 4,
            css_classes = { "ttl-thread-line", "bottom" },
        };
        avatar.clicked.connect (on_avatar_clicked);
        avatar_overlay.add_overlay (avatar);
        avatar_side.append (header_icon);
        avatar_side.append (thread_line_top);
        avatar_side.append (avatar_overlay);
        avatar_side.append (thread_line_bottom);
        status_box.append (avatar_side);
        content_side = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        header_button = new Gtk.Button () {
            visible = false,
            halign = Gtk.Align.START,
        };
        header_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_button.add_css_class ("ttl-status-heading-padding");
        header_button.add_css_class ("ttl-status-heading");
        header_label = new RichLabel () {
            use_markup = false,
        };
        header_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        header_label.add_css_class ("font-bold");
        header_button.child = header_label;
        title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            vexpand = true,
            valign = Gtk.Align.START,
        };
        name_flowbox = new Gtk.FlowBox () {
            selection_mode = Gtk.SelectionMode.NONE,
            column_spacing = 6,
            max_children_per_line = 100,
        };
        name_button = new Gtk.Button () {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
        };
        name_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        name_button.add_css_class ("ttl-name-button");
        name_label = new RichLabel () {
            visible = true,
            ellipsize = true,
            smaller_emoji_pixel_size = true,
            lines = -1,
        };
        name_label.add_css_class ("font-bold");
        name_button.child = name_label;
        var name_fb_child = new Gtk.FlowBoxChild () {
            focusable = false,
            child = name_button,
        };
        handle_label = new Gtk.Label ("Handle") {
            single_line_mode = true,
            xalign = 0,
            hexpand = true,
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
        };
        handle_label.add_css_class ("body");
        handle_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        var handle_fb_child = new Gtk.FlowBoxChild () {
            can_target = false,
            child = handle_label,
        };
        name_flowbox.append (name_fb_child);
        name_flowbox.append (handle_fb_child);
        title_box.append (name_flowbox);
        indicators = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3) {
            margin_start = 6,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
        };
        pin_indicator = new Gtk.Image.from_icon_name ("view-pin-symbolic") {
            icon_size = Gtk.IconSize.INHERIT,
            visible = false,
            tooltip_text = _("Pinned"),
        };
        pin_indicator.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        indicators.append (pin_indicator);
        edited_indicator = new Gtk.Image.from_icon_name ("edit-symbolic") {
            icon_size = Gtk.IconSize.INHERIT,
            visible = false,
            tooltip_text = _("Edited"),
        };
        edited_indicator.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        indicators.append (edited_indicator);
        visibility_indicator = new Gtk.Image () {
            icon_size = Gtk.IconSize.INHERIT,
            visible = true,
        };
        visibility_indicator.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        indicators.append (visibility_indicator);
        date_label = new Gtk.Label ("Yesterday") {
            xalign = 0,
        };
        date_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        indicators.append (date_label);
        menu_button = new Gtk.MenuButton () {
            icon_name = "view-more-horizontal-symbolic",
            visible = false,
        };
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        menu_button.add_css_class (Granite.STYLE_CLASS_CIRCULAR);
        menu_button.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        indicators.append (menu_button);
        title_box.append (indicators);
        content_column = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        content_column.add_css_class ("ttl-status-content");
        spoiler_status_con = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            visible = false,
            margin_bottom = 12,
        };
        var content_warning = new Gtk.Button.from_icon_name ("dialog-warning-symbolic") {
            valign = Gtk.Align.CENTER,
            tooltip_text = _("Show Less"),
        };
        content_warning.add_css_class (Granite.STYLE_CLASS_CIRCULAR);
        content_warning.clicked.connect (toggle_spoiler);
        spoiler_status_con.append (content_warning);
        spoiler_label_rev = new Gtk.Label (null) {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            hexpand = true,
            xalign = 0,
        };
        spoiler_label_rev.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        spoiler_status_con.append (spoiler_label_rev);
        content_column.append (spoiler_status_con);
        spoiler_stack = new Gtk.Stack () {
            vhomogeneous = false,
            hhomogeneous = false,
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            interpolate_size = true,
        };
        spoiler_button = new Gtk.Button () {
            receives_default = true,
            tooltip_text = _("Show More"),
        };
        spoiler_button.add_css_class ("spoiler");
        spoiler_button.clicked.connect (toggle_spoiler);
        var spoiler_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = margin_end = margin_top = margin_bottom = 12,
        };
        var spoiler_image = new Gtk.Image.from_icon_name ("dialog-warning-symbolic");
        spoiler_box.append (spoiler_image);
        spoiler_label = new Gtk.Label ("Spoiler Text Here") {
            visible = true,
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
        };
        spoiler_box.append (spoiler_label);
        spoiler_button.child = spoiler_box;
        spoiler_stack.add_named (spoiler_button, "spoiler");
        content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        content = new MarkupView ();
        content_box.append (content);
        spoiler_stack.add_named (content_box, "content");
        content_column.append (spoiler_stack);
        content_side.append (header_button);
        content_side.append (title_box);
        content_side.append (content_column);
        status_box.append (content_side);
        status_box.set_parent (this);
        name_label.use_markup = false;
        avatar_overlay.set_size_request (avatar.size, avatar.size);
        open.connect (on_open);
        // TODO: handle settings
        edit_history_simple_action = new SimpleAction ("edit-history", null);
        edit_history_simple_action.activate.connect (view_edit_history);

        stats_simple_action = new SimpleAction ("status-stats", null);
        stats_simple_action.activate.connect (view_stats);

        action_group = new SimpleActionGroup ();
        action_group.add_action_entries (ACTION_ENTRIES, this);
        action_group.add_action (stats_simple_action);
        action_group.add_action (edit_history_simple_action);

        insert_action_group ("status", action_group);
        stats_simple_action.set_enabled (false);

        name_button.clicked.connect (on_name_button_clicked);
    }

    private void on_name_button_clicked () {
        status.formal.account.open ();
    }

    private bool has_stats { get { return status.formal.reblogs_count != 0 || status.formal.favourites_count != 0; } }
    private void show_view_stats_action () {
        stats_simple_action.set_enabled (has_stats);
    }

    public Status (API.Status status) {
        Object (kind_instigator: status.account, status: status);

        if (kind == null && status.reblog != null) {
            kind = Services.Accounts.InstanceAccount.KIND_REMOTE_REBLOG;
        }
        init_menu_button ();
    }

    ~Status () {
        debug ("Destroying Status Widget");
        if (context_menu != null) {
            context_menu.menu_model = null;
            context_menu.dispose ();
        }
    }

    protected void init_menu_button () {
        if (context_menu == null) {
            create_actions ();
        }
        menu_button.popover = context_menu;
        menu_button.visible = true;
    }

    protected void create_actions () {
        create_context_menu ();
        if (status.formal.account.is_self ()) {
            if (status.formal.visibility != "direct") {
                toggle_pinned_simple_action = new SimpleAction ("toggle-pinned", null);
                toggle_pinned_simple_action.activate.connect (toggle_pinned);
                toggle_pinned_simple_action.set_enabled (false);
                action_group.add_action (toggle_pinned_simple_action);
            }

            var edit_status_simple_action = new SimpleAction ("edit-status", null);
            edit_status_simple_action.activate.connect (edit_status);
            action_group.add_action (edit_status_simple_action);

            var delete_status_simple_action = new SimpleAction ("delete-status", null);
            delete_status_simple_action.activate.connect (delete_status);
            action_group.add_action (delete_status_simple_action);
        }
    }

    private MenuItem pin_menu_item;
    protected void create_context_menu () {
        var menu_model = new Menu ();
        menu_model.append (_("Open in Browser"), "status.open-in-browser");
        menu_model.append (_("Copy URL"), "status.copy-url");

        var stats_menu_item = new MenuItem (_("View Stats"), "status.status-stats");
        stats_menu_item.set_attribute_value ("hidden-when", "action-disabled");
        menu_model.append_item (stats_menu_item);

        var edit_history_menu_item = new MenuItem (_("View Edit History"), "status.edit-history");
        edit_history_menu_item.set_attribute_value ("hidden-when", "action-disabled");
        menu_model.append_item (edit_history_menu_item);

        if (status.formal.account.is_self ()) {
            pin_menu_item = new MenuItem (_("Pin"), "status.toggle-pinned");
            update_toggle_pinned_label ();
            pin_menu_item.set_attribute_value ("hidden-when", "action-disabled");
            menu_model.append_item (pin_menu_item);
            menu_model.append (_("Edit"), "status.edit-status");
            menu_model.append (_("Delete"), "status.delete-status");
        }
        context_menu = new Gtk.PopoverMenu.from_model (menu_model);
    }

    private void copy_url () {
        // TODO: copy to clipboard
    }

    private void open_in_browser () {
        // TODO: open in browser
    }

    private void view_edit_history () {
        // TODO: view edit history
    }

    private void view_stats () {
        // TODO: view stats
    }

    private void on_edit (API.Status x) {
        this.status.patch (x);
        bind ();
    }

    public signal void pin_changed ();

    private void toggle_pinned () {
        var p_action = status.formal.pinned ? "unpin" : "pin";
        new Services.Network.Request.POST (@"/api/v1/statuses/$(status.formal.id)/$p_action")
            .with_account (accounts.active)
            .then (() => {
                this.status.formal.pinned = p_action == "pin";
                entity_cache.remove (this.status.formal.url);
                pin_changed ();
            })
            .exec ();
    }

    private void edit_status () {
        // TODO: edit status
    }

    private void delete_status () {
        // TODO: delete status
    }

    protected string spoiler_text {
        owned get {
            var text = status.formal.spoiler_text;
            if (text == null || text == "") {
                return _("Show More");
            } else {
                spoiler_text_revealed = text;
                return text;
            }
        }
    }
    public string spoiler_text_revealed { get; set; default = _("Sensitive"); }
    public bool reveal_spoiler { get; set; default = true; }

    string expanded_separator = ".";
    protected string date {
        owned get {
            if (expanded) {
                var date_local = _("%B %e, %Y");
                var date_parsed = new DateTime.from_iso8601 (status.formal.edited_at ?? status.formal.created_at, null);
                date_parsed = date_parsed.to_timezone (new TimeZone.local ());

                return date_parsed.format (@"$date_local $expanded_separator %H:%M").replace (" ", "");
            } else {
                return Utils.DateTime.humanize (status.formal.edited_at ?? status.formal.created_at);
            }
        }
    }

    public string title_text {
        owned get {
            return status.formal.account.display_name;
        }
    }

    public string subtitle_text {
        owned get {
            return status.formal.account.handle;
        }
    }

    public string? avatar_url {
        owned get {
            return status.formal.account.avatar;
        }
    }

    public signal void open ();
    public virtual void on_open () {
        if (status.id == "") {
            on_avatar_clicked ();
        } else {
            status.open ();
        }
    }

    Avatar? actor_avatar = null;
    ulong header_button_activate;
    private Binding actor_avatar_binding;
    const string[] SHOULD_SHOW_ACTOR_AVATAR = {
        Services.Accounts.InstanceAccount.KIND_REBLOG,
        Services.Accounts.InstanceAccount.KIND_REMOTE_REBLOG,
        Services.Accounts.InstanceAccount.KIND_FAVORITE,
    };

    protected virtual void change_kind () {
        string icon = null;
        string descr = null;
        string label_url = null;
        accounts.active.describe_kind (this.kind, out icon, out descr, this.kind_instigator, out label_url);

        if (icon == null) {
            return;
        }

        header_icon.visible = header_button.visible = true;

        if (kind in SHOULD_SHOW_ACTOR_AVATAR) {
            if (actor_avatar == null) {
                actor_avatar = new Avatar () {
                    size = 34,
                    valign = Gtk.Align.START,
                    halign = Gtk.Align.START,
                };
                actor_avatar.add_css_class ("ttl-status-avatar-actor");

                if (this.kind_instigator != null) {
                    actor_avatar_binding = this.bind_property (
                        "kind_instigator", actor_avatar, "account", BindingFlags.SYNC_CREATE
                    );
                    actor_avatar.clicked.connect (open_kind_instigator_account);
                } else {
                    actor_avatar_binding = this.bind_property (
                        "account", actor_avatar, "account", BindingFlags.SYNC_CREATE
                    );
                    actor_avatar.clicked.connect (open_status_account);
                }
            }
            avatar.add_css_class ("ttl-status-avatar-border");
            avatar_overlay.child = actor_avatar;
        } else if (actor_avatar != null) {
            actor_avatar_binding.unbind ();
            avatar_overlay.child = null;
        }

        header_icon.icon_name = icon;
        header_label.instance_emojis = this.kind_instigator.emojis_map;
        header_label.label = descr;

        if (header_button_activate > 0) {
            header_button.disconnect (header_button_activate);
        }
        header_button_activate = header_button.clicked.connect (() => header_label.on_activate_link (label_url));
    }

    private void open_kind_instigator_account () {
        this.kind_instigator.open ();
    }

    private void open_status_account () {
        status.account.open ();
    }

    private void update_spoiler_status () {
        spoiler_status_con.visible = reveal_spoiler && status.formal.has_spoiler;
        spoiler_stack.visible_child_name = reveal_spoiler ? "content" : "spoiler";
    }

    public void show_toggle_pinned_action () {
        if (toggle_pinned_simple_action != null) {
            toggle_pinned_simple_action.set_enabled (true);
        }
    }

    private void update_toggle_pinned_label () {
        if (pin_menu_item != null) {
            pin_menu_item.set_label (status?.formal?.pinned ? _("Unpin") : _("Pin"));
        }
    }

    private Gtk.Button prev_card;
    // TODO: attachments
    // TODO: vote box
    const string[] ALLOWED_CARD_TYPES = { "link", "video" };
    ulong[] formal_handler_ids = {};
    ulong[] this_handler_ids = {};
    Binding[] bindings = {};
    protected virtual void bind () {
        soft_unbind ();
        if (actions != null) {
            actions.unbind ();
            content_column.remove (actions);
        }
        actions = new ActionsRow (this.status.formal);
       // TODO:  actions.reply.connect (on_reply_button_cilcked);
        content_column.append (actions);

        this.content.mentions = status.formal.mentions;
        this.content.instance_emojis = status.formal.emojis_map;
        this.content.content = status.formal.content;

        if (quoted_status_btn != null) {
            content_box.remove (quoted_status_btn);
        }
        if (status.formal.quote != null && !is_quote) {
            try {
                var quoted_status = (Status) status.formal.quote.to_widget ();
                quoted_status.is_quote = true;
                quoted_status.add_css_class (Granite.STYLE_CLASS_FRAME);
                quoted_status.add_css_class ("ttl-quote");
                quoted_status_btn = new Gtk.Button () {
                    child = quoted_status,
                    css_classes = { Granite.STYLE_CLASS_FLAT, "ttl-flat-button" },
                };
                quoted_status_btn.clicked.connect (quoted_status.on_open);
                content_box.append (quoted_status_btn);
            } catch (Error e) {
                critical (@"Widgets.Status ($(status.formal.id)): Couldn't build quote");
            }
        }
        spoiler_label.label = this.spoiler_text;
        spoiler_label_rev.label = this.spoiler_text_revealed;
        reveal_spoiler = !status.formal.has_spoiler || settings.show_spoilers;
        update_spoiler_status ();
        this_handler_ids += notify["reveal-spoiler"].connect (update_spoiler_status);
        handle_label.label = this.subtitle_text;
        date_label.label = this.date;
        pin_indicator.visible = status.formal.pinned;
        update_toggle_pinned_label ();
        edited_indicator.visible = status.formal.is_edited;
        edit_history_simple_action.set_enabled (status.formal.is_edited);
        var t_visibility = accounts.active.visibility[status.formal.visibility];
        visibility_indicator.icon_name = t_visibility.small_icon_name;
        visibility_indicator.tooltip_text = t_visibility.name;

        if (change_background_on_direct && status.formal.visibility == "direct") {
            add_css_class ("direct");
        } else {
            remove_css_class ("direct");
        }
        avatar.account = status.formal.account;
        //reactions = status.formal.compat_status_reactions;

        name_label.instance_emojis = status.formal.account.emojis_map;
        name_label.label = title_text;
        // TODO: Polls
        // TODO: Attachments
        if (prev_card != null) {
            content_box.remove (prev_card);
        }
        //if (!settings.hide_preview_cards
        //    && status.formal.card != null
        //    && status.formal.card.kind in ALLOWED_CARD_TYPES) {
        //    try {
        //        prev_card = (Gtk.Button) status.formal.card.to_widget ();
        //        prev_card.clicked.connect (open_card_url);
        //        content_box.append (prev_card);
        //    } catch (Error e) {
        //        warning (e.message);
        //    }
        //}

        show_view_stats_action ();
        formal_handler_ids += status.formal.notify["reblogs-count"].connect (show_view_stats_action);
        formal_handler_ids += status.formal.notify["favorites-count"].connect (show_view_stats_action);
        formal_handler_ids += status.formal.notify["tuba-thread-role"].connect (install_thread_line);
    }

    public void soft_unbind () {
        foreach (var handler_id in formal_handler_ids) {
            status.formal.disconnect (handler_id);
        }
        formal_handler_ids = {};

        foreach (var handler_id in this_handler_ids) {
            this.disconnect (handler_id);
        }
        this_handler_ids = {};

        foreach (var binding in bindings) {
            binding.unbind ();
        }
        bindings = {};
    }

    private void open_card_url () {
        // TODO: PreviewCard
    }

    private void on_reply (API.Status x) {
        // TODO: reply callback
    }

    private void on_reply_button_clicked () {
        // TODO: Compose reply
    }

    public void toggle_spoiler () {
        reveal_spoiler = !reveal_spoiler;
    }

    public void on_avatar_clicked () {
        status.formal.account.open ();
    }

    private bool expanded = false;
    public void expand_root () {
        if (expanded) {
            return;
        }

        expanded = true;
        //content.selectable = true;
        //content.add_css_class = { "ttl-large-body" };
        status_box.remove (avatar_side);
        title_box.prepend (avatar_side);
        title_box.spacing = 14;
        name_flowbox.max_children_per_line = 1;
        name_flowbox.valign = Gtk.Align.CENTER;
        content_side.spacing = 10;
        indicators.remove (date_label);
        if (status.formal.is_edited) {
            indicators.remove (edited_indicator);
        }
        indicators.remove (visibility_indicator);
        date_label.label = this.date;
        date_label.wrap = true;
    }

    public void install_thread_line () {
        if (expanded || !enable_thread_lines) {
            return;
        }
        // TODO: switch case thread role
    }
}
