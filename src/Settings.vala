public class Pachy.Settings : GLib.Settings {
    private static Settings? _instance;
    public static Settings get_default () {
        if (_instance == null) {
            _instance = new Settings ();
        }
        return _instance;
    }

    private Settings () {
        Object (schema_id: "com.github.leggettc18.pachy");
    }

    public string active_account {
        owned get { return get_string ("active-account"); }
        set { set_string ("active-account", value); }
    }

    public bool work_in_background {
        get { return get_boolean ("work-in-background"); }
        set { set_boolean ("work-in-background", value); }
    }
}
