public class Pachy.Utils.Host {
    public static bool open_uri (string _uri) {
        var uri = _uri;
        if (!(":" in uri)) {
            uri = "file://" + _uri;
        }

        // TODO: Strip Tracking
        try {
            var success = AppInfo.launch_default_for_uri (uri, null);
            if (!success) {
                throw new PachyError.USER ("launch_default_for_uri failed");
            }
        } catch (Error e) {
            var launcher = new Gtk.UriLauncher (uri);
            launcher.launch.begin (app.active_window, null, (obj, res) => {
                try {
                    launcher.launch.end (res);
                } catch (Error e) {
                    warning (@"Error opening uri \"$uri\": $(e.message)");
                }
            });
        }
        return true;
    }

    public static void copy (string str) {
        Gdk.Display display = Gdk.Display.get_default ();
        if (display == null) {
            return;
        }
        display.get_clipboard ().set_text (str);
    }
}
