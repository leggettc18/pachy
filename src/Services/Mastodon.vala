public class Pachy.Services.Mastodon : Object {
    private const string REGISTER_CLIENT_URL = "%s/api/v1/apps";
    private const string OAUTH_OPEN_URL =
        "%s/oauth/authorize?client_id=%s&scope=read+write+push&redirect_uri=pachy://auth_code&response_type=code";
    private const string ACCESS_TOKEN_URL = "%s/oauth/token";
    public App app { get; construct; }

    private Soup.Session session;
    private Json.Parser parser;
    private Settings settings;

    private static Mastodon? _instance;
    public static Mastodon get_default () {
        if (_instance == null) {
            _instance = new Mastodon ();
        }
        return _instance;
    }

    private Mastodon () {
        Object ();
    }

    construct {
        session = new Soup.Session ();
        parser = new Json.Parser ();
        settings = Settings.get_default ();
    }

    public string get_oauth_open_url () {
        return OAUTH_OPEN_URL.printf (settings.instance_url, settings.client_id);
    }

    public async void register_client () {
        debug ("registering client");
        string url = REGISTER_CLIENT_URL.printf (settings.instance_url);
        var form_data = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
        form_data.append_form_string ("client_name", Build.NAME);
        form_data.append_form_string ("redirect_uris", "pachy://auth_code");
        form_data.append_form_string ("scopes", "read write push");
        form_data.append_form_string ("website", "https://github.com/leggettc18/pachy");
        var message = new Soup.Message.from_multipart (url, form_data);
        message.method = "POST";
        try {
            var stream = yield session.send_and_read_async (message, Priority.HIGH, null);
            parser.load_from_data ((string) stream.get_data ());
            var root = parser.get_root ().get_object ();
            settings.client_id = root.get_string_member ("client_id");
            settings.client_secret = root.get_string_member ("client_secret");
        } catch (Error e) {
            error (e.message);
        }
        yield request_client_auth_token ();
    }

    public async void request_client_auth_token () {
        if (yield verify_client_credentials ()) {
            debug ("client already registered");
            return;
        }
        string url = ACCESS_TOKEN_URL.printf (settings.instance_url);
        var form_data = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
        form_data.append_form_string ("client_id", settings.client_id);
        form_data.append_form_string ("client_secret", settings.client_secret);
        form_data.append_form_string ("redirect_uri", "pachy://auth_code");
        form_data.append_form_string ("grant_type", "client_credentials");
        var message = new Soup.Message.from_multipart (url, form_data) {
            method = "POST",
        };
        try {
            var stream = yield session.send_and_read_async (message, Priority.HIGH, null);
            parser.load_from_data ((string) stream.get_data ());
            var root = parser.get_root ().get_object ();
            settings.client_access_token = root.get_string_member ("access_token");
            debug ("client_access_token: %s", settings.client_access_token);
        } catch (Error e) {
            error (e.message);
        }
    }

    public async bool verify_client_credentials () {
        if (settings.client_access_token == "") {
            debug ("no client_access token available");
            return false;
        }
        string url = "%s/api/v1/apps/verify_credentials".printf (settings.instance_url);
        var message = new Soup.Message ("GET", url);
        message.request_headers.remove ("Authorization");
        message.request_headers.append ("Authorization", @"Bearer $(settings.client_access_token)");
        try {
            var stream = yield session.send_and_read_async (message, Priority.HIGH, null);
        } catch (Error e) {
            error (e.message);
        }
        debug ("status_code: %u", message.status_code);

        return message.status_code == 200;
    }

    public async void request_auth_token (string uri) {
        debug ("requesting user auth token");
        try {
            debug (uri);
            var parsed_uri = Uri.parse (uri, UriFlags.NONE);
            debug (parsed_uri.get_query ());
            var parameters = Uri.parse_params (parsed_uri.get_query ());
            var list = parameters.get_keys ();
            string auth_code = parameters.get ("code");
            var form_data = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
            form_data.append_form_string ("client_id", settings.client_id);
            form_data.append_form_string ("client_secret", settings.client_secret);
            form_data.append_form_string ("redirect_uri", "pachy://auth_code");
            form_data.append_form_string ("grant_type", "authorization_code");
            form_data.append_form_string ("code", auth_code);
            form_data.append_form_string ("scope", "read write push");
            string url = ACCESS_TOKEN_URL.printf (settings.instance_url);
            debug (url);
            var message = new Soup.Message.from_multipart (url, form_data);
            message.method = "POST";
            var stream = yield session.send_and_read_async (message, Priority.HIGH, null);
            parser.load_from_data ((string) stream.get_data ());
            var root = parser.get_root ().get_object ();
            settings.user_access_token = root.get_string_member ("access_token");
            debug ("obtained user auth token");
        } catch (Error e) {
            error (e.message);
        }
    }

    public async string get_display_name () {
        var url = "%s/api/v1/accounts/verify_credentials".printf (settings.instance_url);
        var message = new Soup.Message ("GET", url);
        message.request_headers.remove ("Authorization");
        message.request_headers.append ("Authorization", @"Bearer $(settings.user_access_token)");
        var stream = yield session.send_and_read_async (message, Priority.HIGH, null);
        parser.load_from_data ((string) stream.get_data ());
        var root = parser.get_root ().get_object ();
        return root.get_string_member ("display_name");
    }
}
