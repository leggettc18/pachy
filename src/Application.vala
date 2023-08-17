public class App: Gtk.Application {
    public App () {
        Object (
            application_id: "com.github.leggettc18.pachy",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        base.activate ();
        var start_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label (""),
        };
        start_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        start_header.pack_start (new Gtk.WindowControls (Gtk.PackType.START));

        var start_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        start_box.append (start_header);

        var end_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
        };
        end_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        end_header.pack_end (new Gtk.WindowControls (Gtk.PackType.END));

        var end_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        end_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        end_box.append (end_header);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = start_box,
            end_child = end_box,
            resize_start_child = false,
            shrink_end_child = false,
            shrink_start_child = false,
        };

        var main_window = new Gtk.ApplicationWindow (this) {
            child = paned,
            default_height = 400,
            default_width = 600,
            titlebar = new Gtk.Grid () { visible = false },
            title = _("Pachy")
        };
        main_window.present ();
    }

    public static int main (string[] args) {
        return new App ().run (args);
    }
}
