public class Pachy.Services.Accounts.Mastodon.Account : Services.Accounts.InstanceAccount {
    public const string BACKEND = "Mastodon";

    class Test : AccountStore.BackendTest {
        public override string? get_backend (Json.Object obj) {
            return BACKEND;
        }
    }

    public static void register (AccountStore store) {
        store.backend_tests.add (new Test ());
        store.create_for_backend[BACKEND].connect ((node) => {
            try {
                var account = API.Entity.from_json (typeof (Account), node) as Account;
                account.backend = BACKEND;
                return account;
            } catch (Error e) {
                warning (@"Error creating backend: $(e.message)");
            }
            return null;
        });
    }
}
