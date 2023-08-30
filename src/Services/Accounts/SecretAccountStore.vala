public class Pachy.Services.Accounts.SecretAccountStore : AccountStore {
    const string VERSION = "1";

    Secret.Schema schema;
    HashTable<string, Secret.SchemaAttributeType> schema_attributes;

    public override void init () throws Error {
        message (@"Using libsecret v$(Secret.MAJOR_VERSION).$(Secret.MINOR_VERSION).$(Secret.MICRO_VERSION)");
        schema_attributes = new HashTable<string, Secret.SchemaAttributeType> (str_hash, str_equal);
        schema_attributes["login"] = Secret.SchemaAttributeType.STRING;
        schema_attributes["version"] = Secret.SchemaAttributeType.STRING;
        schema = new Secret.Schema.newv (Build.DOMAIN, Secret.SchemaFlags.DONT_MATCH_NAME, schema_attributes);

        base.init ();
    }

    public override void load () throws Error {
        var attrs = new HashTable<string, string> (str_hash, str_equal);
        attrs["version"] = VERSION;

        List<Secret.Retrievable> secrets = new List<Secret.Retrievable> ();
        try {
            secrets = Secret.password_searchv_sync (
                schema,
                attrs,
                Secret.SearchFlags.ALL | Secret.SearchFlags.UNLOCK,
                null
            );
        } catch (Error e) {
            critical (@"Error while searching for items in the secret service: $(e.message)");

            // TODO: Display dialog with more info on how to solve
        }

        secrets.foreach (item => {
            var account = secret_to_account (item);
            if (account != null && account.id != "") {
                new Network.Request.GET (@"/api/v1/accounts/$(account.id)")
                    .with_account (account)
                    .then ((sess, msg, in_stream) => {
                        var parser = Network.Network.get_parser_from_inputstream (in_stream);
                        var node = network.parse_node (parser);
                        var acc = API.Account.from (node);

                        if (account.display_name != acc.display_name || account.avatar != acc.avatar) {
                            account.display_name = acc.display_name;
                            account.avatar = acc.avatar;
                            account.emojis = acc.emojis;

                            account_to_secret (account);
                        }
                    })
                    .exec ();
                saved.add (account);
                account.added ();
            }
        });
        changed (saved);
        message (@"Loaded $(saved.size) accounts");
    }

    public override void save () throws Error {
        saved.foreach (account => {
            account_to_secret (account);
            return true;
        });
        message (@"Saved $(saved.size) accounts");
    }

    public override void remove (InstanceAccount account) throws Error {
        base.remove (account);

        var attrs = new HashTable<string, string> (str_hash, str_equal);
        attrs["version"] = VERSION;
        attrs["login"] = account.handle;

        Secret.password_clearv.begin (
            schema,
            attrs,
            null,
            (obj, async_res) => {
                try {
                    Secret.password_clearv.end (async_res);
                } catch (Error e) {
                    warning (e.message);
                }
            }
        );
    }

    void account_to_secret (InstanceAccount account) {
        var attrs = new HashTable<string, string> (str_hash, str_equal);
        attrs["login"] = account.handle;
        attrs["version"] = VERSION;

        var generator = new Json.Generator ();

        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("id");
        builder.add_string_value (account.id);

        builder.set_member_name ("username");
        builder.add_string_value (account.username);

        builder.set_member_name ("display-name");
        builder.add_string_value (account.display_name);

        builder.set_member_name ("acct");
        builder.add_string_value (account.acct);

        builder.set_member_name ("header");
        builder.add_string_value (account.header);

        builder.set_member_name ("avatar");
        builder.add_string_value (account.avatar);

        builder.set_member_name ("url");
        builder.add_string_value (account.url);

        builder.set_member_name ("instance");
        builder.add_string_value (account.instance);

        builder.set_member_name ("client-id");
        builder.add_string_value (account.client_id);

        builder.set_member_name ("client-secret");
        builder.add_string_value (account.client_secret);

        builder.set_member_name ("client-access-token");
        builder.add_string_value (account.client_access_token);

        builder.set_member_name ("user-access-token");
        builder.add_string_value (account.user_access_token);

        builder.set_member_name ("handle");
        builder.add_string_value (account.handle);

        builder.set_member_name ("backend");
        builder.add_string_value (account.backend);

        builder.set_member_name ("emojis");
        builder.begin_array ();
        if (account.emojis?.size > 0) {
            foreach (var emoji in account.emojis) {
                message ("saving emoji: %s - %s", emoji.shortcode, emoji.url);
                builder.begin_object ();
                builder.set_member_name ("shortcode");
                builder.add_string_value (emoji.shortcode);
                builder.set_member_name ("url");
                builder.add_string_value (emoji.url);
                builder.end_object ();
            }
        }
        builder.end_array ();

        builder.end_object ();
        generator.set_root (builder.get_root ());
        var secret = generator.to_data (null);
        /// TRANSLATORS: varialbe is the backend like "Mastodon"
        var label = _("%s Account").printf (account.backend);

        Secret.password_storev.begin (
            schema,
            attrs,
            Secret.COLLECTION_DEFAULT,
            label,
            secret,
            null,
            (obj, async_res) => {
                try {
                    Secret.password_storev.end (async_res);
                    message (@"Saved secret for $(account.handle)");
                } catch (Error e) {
                    warning (e.message);
                }
            }
        );
    }

    InstanceAccount? secret_to_account (Secret.Retrievable item) {
        InstanceAccount? account = null;
        try {
            var secret = item.retrieve_secret_sync ();
            var contents = secret.get_text ();
            var parser = new Json.Parser ();
            parser.load_from_data (contents, -1);
            account = accounts.create_account (parser.get_root ());
        } catch (Error e) {
            warning (e.message);
        }
        return account;
    }
}
