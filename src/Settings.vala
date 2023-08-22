public class Pachy.Settings : GLib.Settings {
    private static Settings? _instance;
    public static Settings get_default () {
        if (_instance == null) {
            _instance = new Settings ();
        }
        return _instance;
    }

    public string instance_url {
        owned get { return get_string ("instance-url"); }
        set { set_string ("instance-url", value); }
    }

    public string client_id {
        owned get { return get_string ("client-id"); }
        set { set_string ("client-id", value); }
    }

    public string client_secret {
        owned get { return get_string ("client-secret"); }
        set { set_string ("client-secret", value); }
    }

    public string client_access_token {
        owned get { return get_string ("client-access-token"); }
        set { set_string ("client-access-token", value); }
    }

    public string user_access_token {
        owned get { return get_string ("user-access-token"); }
        set { set_string ("user-access-token", value); }
    }

    private Settings () {
        Object (schema_id: "com.github.leggettc18.pachy");
    }
}
