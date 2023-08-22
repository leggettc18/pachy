public class Pachy.Dialogs.Authentication : Gtk.Window {
    public App app { get; construct; }

    private Gtk.Stack stack;
    private WebKit.WebView webview;

    public Authentication (App app) {
        Object (
            app: app,
            deletable: true,
            destroy_with_parent: true,
            modal: true,
            title: _("Authenticate with Mastodon"),
            height_request: 575,
            width_request: 475
        );
    }

    construct {
        stack = new Gtk.Stack ();
        var instance_uri_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            valign = Gtk.Align.CENTER,
        };
        var instance_uri_entry_label = new Gtk.Label (_("Enter your instance url"));
        instance_uri_entry_label.add_css_class (Granite.STYLE_CLASS_H1_LABEL);
        instance_uri_box.append (instance_uri_entry_label);
        var instance_uri_entry_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            halign = Gtk.Align.FILL,
            margin_start = margin_end = 12,
        };
        instance_uri_box.append (instance_uri_entry_box);
        var instance_uri_entry = new Gtk.Entry () {
            placeholder_text = "https://mastodon.social",
            hexpand = true,
        };
        instance_uri_entry_box.append (instance_uri_entry);
        var instance_uri_submit_button = new Gtk.Button.from_icon_name ("go-next");
        instance_uri_entry_box.append (instance_uri_submit_button);
        stack.add_named (instance_uri_box, "instance-uri-entry");
        webview = new WebKit.WebView () {
            zoom_level = 0.75,
            vexpand = true,
            hexpand = true,
        };
        stack.add_named (webview, "sign-in-page");
        instance_uri_submit_button.clicked.connect (() => {
            string instance_uri = instance_uri_entry.text;
            debug (instance_uri);
            if (!(instance_uri.substring (0, 8) == "https://" || instance_uri.substring (0, 7) == "http://")) {
                instance_uri = "https://" + instance_uri;
                debug (instance_uri);
            }
            Settings.get_default ().instance_url = instance_uri;
            app.mastodon_service.register_client.begin ((obj, res) => {
                app.mastodon_service.register_client.end (res);
                string oauth_open_url = app.mastodon_service.get_oauth_open_url ();
                var success = AppInfo.launch_default_for_uri (oauth_open_url, null);
                if (!success) {
                    error ("Failed to launch browser");
                }
            });
        });
        stack.visible_child_name = "instance-uri-entry";
        child = stack;
    }
}
