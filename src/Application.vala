namespace Pachy {

public static App app;

public static Settings settings;
public static Services.Accounts.AccountStore accounts;
public static Services.Network.Network network;

public class App : Gtk.Application {
    public const string ACTION_PREFIX = "app.";
    public const string ACTION_SIGN_IN = "sign-in";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_SIGN_IN, action_sign_in },
    };

    private Dialogs.NewAccount? auth_dialog = null;
    private MainWindow? main_window = null;

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

    protected override void activate () {
        base.activate ();

        add_action_entries (ACTION_ENTRIES, this);
        settings = Settings.get_default ();
        network = new Services.Network.Network ();
        accounts = new Services.Accounts.SecretAccountStore ();
        accounts.init ();

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_application_prefer_dark_theme =
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme =
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

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
            }
            main_window.present ();
        }
    }

    private void action_sign_in () {
        if (auth_dialog == null) {
            auth_dialog = new Dialogs.NewAccount ();
            add_window (auth_dialog);
        }
        auth_dialog.present ();
    }
}
}

public static int main (string[] args) {
    Pachy.app = new Pachy.App ();
    return Pachy.app.run (args);
}
