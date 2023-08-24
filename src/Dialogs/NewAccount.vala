public errordomain Pachy.Dialogs.AuthDialogError {
    USER
}

public class Pachy.Dialogs.NewAccount : Gtk.Window {
    const string SCOPES = "read write follow";

    private Gtk.Stack stack;
    private Gtk.Box instance_step;
    private Gtk.Box spinner_page;
    private Gtk.Box done_step;

    private Gtk.Entry instance_entry;
    private Gtk.Label user_greeting;
    private string auth_code;

    private bool is_working = false;
    private string? redirect_uri;
    private Services.Accounts.InstanceAccount account = new Services.Accounts.InstanceAccount.empty ("");

    public NewAccount () {
        Object (
            deletable: true,
            destroy_with_parent: true,
            modal: true,
            title: _("Authenticate with Mastodon"),
            height_request: 575,
            width_request: 475
        );
    }

    construct {
        redirect_uri = "pachy://auth_code";
        stack = new Gtk.Stack ();
        instance_step = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            valign = Gtk.Align.CENTER,
        };
        var instance_uri_entry_label = new Gtk.Label (_("Enter your instance url"));
        instance_uri_entry_label.add_css_class (Granite.STYLE_CLASS_H1_LABEL);
        instance_step.append (instance_uri_entry_label);
        var instance_uri_entry_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            halign = Gtk.Align.FILL,
            margin_start = margin_end = 12,
        };
        instance_step.append (instance_uri_entry_box);
        instance_entry = new Gtk.Entry () {
            placeholder_text = "https://mastodon.social",
            hexpand = true,
        };
        instance_uri_entry_box.append (instance_entry);
        var instance_uri_submit_button = new Gtk.Button.from_icon_name ("go-next");
        instance_uri_entry_box.append (instance_uri_submit_button);
        stack.add_named (instance_step, "instance-uri-entry");
        instance_uri_submit_button.clicked.connect (on_next_clicked);
        spinner_page = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            valign = Gtk.Align.CENTER,
        };
        var spinner = new Gtk.Spinner () {
            spinning = true,
        };
        spinner_page.append (spinner);
        stack.add_named (spinner_page, "spinner-page");
        done_step = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            valign = Gtk.Align.CENTER,
        };
        user_greeting = new Gtk.Label ("");
        var done_label = new Gtk.Label (
            _("Your account has been added, click the button below to begin using Pachy! The Authorization browser tab
              can now be closed.")
        ) {
            max_width_chars = 20,
            wrap = true,
        };
        user_greeting.add_css_class (Granite.STYLE_CLASS_H1_LABEL);
        var done_button = new Gtk.Button.with_label (_("Start using Pachy!"));
        done_button.clicked.connect (() => app.present_window ());
        done_step.append (user_greeting);
        done_step.append (done_label);
        done_step.append (done_button);
        stack.add_named (done_step, "done-step");
        stack.visible_child_name = "instance-uri-entry";
        child = stack;
    }

    private void open_login_page () throws Error {
        message ("Opening login/permission request page");
        var esc_scopes = Uri.escape_string (SCOPES);
        var esc_redirect = Uri.escape_string (redirect_uri);
        var esc_client_id = Uri.escape_string (account.client_id);
        var pars = @"scope=$esc_scopes&response_type=code&redirect_uri=$esc_redirect&client_id=$esc_client_id";
        var url = @"$(account.instance)/oauth/authorize?$pars";
        var success = AppInfo.launch_default_for_uri (url, null);
        if (!success) {
            error ("Failed to launch browser");
        }
    }

    public void redirect (string t_uri) {
        message (@"Received uri: $t_uri");
        try {
            var uri = Uri.parse (t_uri, UriFlags.NONE);
            var uri_params = Uri.parse_params (uri.get_query ());
            if (uri_params.contains ("code")) {
                auth_code = uri_params.get ("code");
            }
        } catch (UriError e) {
            warning (e.message);
            return;
        }

        is_working = false;
        on_next_clicked ();
    }

    private void setup_instance () throws Error {
        message ("Checking instance URL");

        var str = instance_entry.text
            .replace ("/", "")
            .replace (":", "")
            .replace ("https", "")
            .replace ("http", "");
        account.instance = @"https://$str";
        instance_entry.text = str;

        if (str.char_count () <= 0 || !("." in account.instance)) {
            throw new AuthDialogError.USER (_("Please enter a valid instance URL"));
        }
    }

    private async void register_client () throws Error {
        message ("regitering client");
        var msg = new Services.Network.Request.POST ("/api/v1/apps")
            .with_account (account)
            .with_form_data ("client_name", Build.NAME)
            .with_form_data ("redirect_uris", redirect_uri)
            .with_form_data ("scopes", SCOPES)
            .with_form_data ("website", Build.WEBSITE);
        yield msg.await ();

        var parser = Services.Network.Network.get_parser_from_inputstream (msg.response_body);
        var root = network.parse (parser);

        if (root.get_string_member ("name") != Build.NAME) {
            throw new Services.Network.NetworkError.INSTANCE (_("Misconfigured Instance"));
        }

        account.client_id = root.get_string_member ("client_id");
        account.client_secret = root.get_string_member ("client_secret");
        message ("OK: Instance registered client");
        yield request_client_token ();

        open_login_page ();
    }

    private async void request_client_token () throws Error {
        var msg = new Services.Network.Request.POST ("/oauth/token")
            .with_account (account)
            .with_form_data ("client_id", account.client_id)
            .with_form_data ("client_secret", account.client_secret)
            .with_form_data ("redirect_uri", redirect_uri)
            .with_form_data ("grant_type", "client_credentials");
        yield msg.await ();

        var parser = Services.Network.Network.get_parser_from_inputstream (msg.response_body);
        var root = network.parse (parser);

        account.client_access_token = root.get_string_member ("access_token");
        message ("OK: Obtained client access token");
    }

    private async void request_token () throws Error {
        message ("requesting access token");
        var token_req = new Services.Network.Request.POST ("/oauth/token")
            .with_account (account)
            .with_form_data ("client_id", account.client_id)
            .with_form_data ("client_secret", account.client_secret)
            .with_form_data ("redirect_uri", redirect_uri)
            .with_form_data ("grant_type", "authorization_code")
            .with_form_data ("code", auth_code);
        yield token_req.await ();

        var parser = Services.Network.Network.get_parser_from_inputstream (token_req.response_body);
        var root = network.parse (parser);

        account.user_access_token = root.get_string_member ("access_token");
        message ("OK: Obtained user access token");

        yield account.verify_credentials ();

        account = accounts.create_account (account.to_json ());
        message ("saving account");
        accounts.add (account);

        /// TRANSLATORS: the variable here is the user's display name,
        /// which could basically be anything, or it is their username
        /// if a display name has not been set.
        user_greeting.label = _("Hello, %s!").printf (account.display_name);
        stack.visible_child = done_step;

        message ("switching to new account");
        accounts.activate (account);
    }

    private async void step () throws Error {
        if (stack.visible_child == instance_step) {
            stack.visible_child = spinner_page;
            setup_instance ();
            yield accounts.guess_backend (account);
        }
        if (account.client_secret == null || account.client_id == null) {
            yield register_client ();
            return;
        }
        yield request_token ();
    }

    private void on_next_clicked () {
        if (is_working) {
            return;
        }

        is_working = true;
        step.begin ((obj, res) => {
            try {
                step.end (res);
            } catch (Services.Network.NetworkError.INSTANCE e) {
                warning (e.message);
            } catch (Error e) {
                warning (e.message);
            }
        });
    }
}
