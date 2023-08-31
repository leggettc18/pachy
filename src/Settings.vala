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

    public int timeline_page_size {
        get { return get_int ("timeline-page-size"); }
        set { set_int ("timeline-page-size", value); }
    }

    public bool live_updates {
        get { return get_boolean ("live-updates"); }
        set { set_boolean ("live-updates", value); }
    }

    public bool public_live_updates {
        get { return get_boolean ("public-live-updates"); }
        set { set_boolean ("public-live-updates", value); }
    }

    public string default_post_visibility {
        owned get { return get_string ("default-post-visibility"); }
        set { set_string ("default-post-visibility", value); }
    }

    public bool show_spoilers {
        get { return get_boolean ("show-spoilers"); }
        set { set_boolean ("show-spoilers", value); }
    }

    public bool aggressive_resolving {
        get { return get_boolean ("aggressive-resolving"); }
        set { set_boolean ("aggressive-resolving", value); }
    }

    public bool enlarge_custom_emojis {
        get { return get_boolean ("enlarge-custom-emojis"); }
        set { set_boolean ("enlarge-custom-emojis", value); }
    }
}
