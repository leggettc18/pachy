namespace Pachy {

public errordomain PachyError {
    USER,
    PARSING,
    INSTANCE,
    INTERNAL
}

public static App app;

public static Settings settings;
public static Services.Accounts.AccountStore accounts;
public static Services.Network.Network network;
public static Services.Network.Streams streams;

public static Services.Cache.ImageCache image_cache;
public static Services.Cache.EntityCache entity_cache;

public static Regex custom_emoji_regex;
public static Regex rtl_regex;
public static bool is_rtl;

public class App : Gtk.Application {
    public const string ACTION_PREFIX = "app.";
    public const string ACTION_SIGN_IN = "sign-in";
    public const string ACTION_QUIT = "quit";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_SIGN_IN, action_sign_in },
        { ACTION_QUIT, action_quit },
    };

    private Dialogs.NewAccount? auth_dialog = null;
    public MainWindow? main_window { get; set; default = null; }

    public signal void refresh ();

    public App () {
        Object (
            application_id: "com.github.leggettc18.pachy",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    protected override void open (File[] files, string hint) {
        debug ("hint: %s", hint);
        foreach (File file in files) {
            if (file.get_uri ().contains ("pachy://auth_code")) {
                if (auth_dialog != null) {
                    auth_dialog.redirect (file.get_uri ());
                }
            }
        }
    }

    protected override void startup () {
        base.startup ();
        try {
            Granite.init ();
            settings = Settings.get_default ();
            streams = new Services.Network.Streams ();
            network = new Services.Network.Network ();
            entity_cache = new Services.Cache.EntityCache ();
            image_cache = new Services.Cache.ImageCache () {
                maintenance_secs = 60 * 5
            };
            accounts = new Services.Accounts.SecretAccountStore ();
            accounts.init ();
        } catch (Error e) {
            error ("Could not start application: %s", e.message);
        }
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_application_prefer_dark_theme =
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme =
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, { "<Ctrl>q" });
        set_accels_for_action ("window.close", { "<Ctrl>w" });
        add_action_entries (ACTION_ENTRIES, this);
    }

    protected override void activate () {
        base.activate ();

        present_window ();
    }

    public void present_window (bool destroy_main = false) {
        if (accounts.saved.is_empty) {
            if (main_window != null && destroy_main) {
                main_window.hide ();
            }
            message ("presenting new account dialog");
            ((SimpleAction) lookup_action (ACTION_SIGN_IN)).activate (null);
        } else {
            message ("presenting main window");
            if (main_window == null) {
                main_window = new MainWindow ();
                add_window (main_window);
                is_rtl = Gtk.Widget.get_default_direction () == Gtk.TextDirection.RTL;
            }
            main_window.present ();
        }

        if (main_window != null) {
            main_window.close_request.connect (on_window_closed);
        }
    }

    private bool on_window_closed () {
        if (!settings.work_in_background || accounts.saved.is_empty) {
            main_window.hide_on_close = false;
        } else {
            main_window.hide_on_close = true;
        }
        return false;
    }

    private void action_sign_in () {
        if (auth_dialog == null) {
            auth_dialog = new Dialogs.NewAccount ();
            add_window (auth_dialog);
        }
        auth_dialog.present ();
    }

    private void action_quit () {
        app.quit ();
    }

    private void refresh_activated () {
        refresh ();
    }
}
}

public static int main (string[] args) {
    try {
        Pachy.custom_emoji_regex = new Regex (
            "(:[a-zA-Z0-9_]{2,}:)",
            RegexCompileFlags.OPTIMIZE
        );
    } catch (RegexError e) {
        warning (e.message);
    }
    try {
        Pachy.rtl_regex = new Regex (
            "[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]",
            RegexCompileFlags.OPTIMIZE,
            RegexMatchFlags.ANCHORED
        );
    } catch (RegexError e) {
        warning (e.message);
    }

    Pachy.app = new Pachy.App ();
    return Pachy.app.run (args);
}
