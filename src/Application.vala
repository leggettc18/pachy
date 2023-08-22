public class Pachy.App : Gtk.Application {
    public const string ACTION_PREFIX = "app.";
    public const string ACTION_SIGN_IN = "sign-in";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_SIGN_IN, action_sign_in },
    };

    public Settings settings { get; private set; }

    private Dialogs.Authentication? auth_dialog = null;
    public Services.Mastodon? mastodon_service { get; private set; }

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
                if (active_window != null && active_window == auth_dialog) {
                    mastodon_service.request_auth_token.begin (file.get_uri (), (obj, res) => {
                        var main_window = new MainWindow (this);
                        add_window (main_window);
                        main_window.present ();
                        auth_dialog.destroy ();
                    });
                }
            }
        }
    }

    protected override void activate () {
        base.activate ();

        add_action_entries (ACTION_ENTRIES, this);
        settings = Settings.get_default ();

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_application_prefer_dark_theme =
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme =
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        mastodon_service = Services.Mastodon.get_default ();

        if (settings.client_id == "" || settings.client_secret == "" ||
            settings.user_access_token == "") {
            ((SimpleAction) lookup_action (ACTION_SIGN_IN)).activate (null);
        } else {
            var main_window = new MainWindow (this);
            add_window (main_window);
            main_window.present ();
        }
    }

    private void action_sign_in () {
        auth_dialog = new Dialogs.Authentication (this);
        add_window (auth_dialog);
        auth_dialog.present ();
    }
}

public static int main (string[] args) {
    return new Pachy.App ().run (args);
}
