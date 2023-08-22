public class Pachy.MainWindow : Gtk.ApplicationWindow {
    public App app { get; construct; }
    private Gtk.HeaderBar start_header;
    private Gtk.HeaderBar end_header;
    private Gtk.Box start_box;
    private Gtk.Box end_box;
    private Gtk.Paned paned;
    private Gtk.Button sign_in_button;

    public MainWindow (App app) {
        Object (app: app);
    }

    construct {
        start_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label (""),
        };
        start_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        start_header.pack_start (new Gtk.WindowControls (Gtk.PackType.START));

        start_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        start_box.append (start_header);

        end_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
        };
        end_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        end_header.pack_end (new Gtk.WindowControls (Gtk.PackType.END));

        end_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.FILL,
            vexpand = true,
        };
        end_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        end_box.append (end_header);

        var sign_in_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            hexpand = false,
            vexpand = true,
        };

        sign_in_button = new Gtk.Button.with_label (_("Sign In")) {
            action_name = App.ACTION_PREFIX + App.ACTION_SIGN_IN,
            hexpand = false,
            margin_start = margin_end = 12,
        };

        var display_name = new Gtk.Label ("");
        app.mastodon_service.get_display_name.begin ((obj, res) => {
            display_name.label = app.mastodon_service.get_display_name.end (res);
        });
        sign_in_box.append (display_name);
        end_box.append (sign_in_box);

        paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = start_box,
            end_child = end_box,
            resize_start_child = false,
            shrink_end_child = false,
            shrink_start_child = false,
        };

        child = paned;
        default_height = 400;
        default_width = 600;
        titlebar = new Gtk.Grid () { visible = false };
        title = "%s - %s".printf (Build.NAME, Build.VERSION);
    }
}
