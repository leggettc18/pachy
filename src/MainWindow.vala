public class Pachy.MainWindow : Gtk.ApplicationWindow {
    private Gtk.Paned paned;
    private Views.Sidebar sidebar;
    private Views.Base base_view;

    construct {
        default_height = 400;
        default_width = 600;
        titlebar = new Gtk.Grid () { visible = false };
        title = "%s - %s".printf (Build.NAME, Build.VERSION);
        if (Build.PROFILE == "development") {
            add_css_class ("devel");
        }

        sidebar = new Views.Sidebar ();

        base_view = new Views.Base () {
            base_status = new Views.Base.StatusMessage (),
        };

        paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = sidebar,
            end_child = base_view,
            resize_start_child = false,
            shrink_end_child = false,
            shrink_start_child = false,
        };

        child = paned;
    }

    public bool back () {
        // TODO: handle navigation
        return true;
    }

    public void go_back_to_start () {
        var navigated = true;
        while (navigated) {
            navigated = false;
            // TODO: Handle Navigation
        }
    }
}
