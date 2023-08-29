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

    public static API.Place place_home = new API.Place () {
        icon = "user-home-symbolic",
        title = _("Home"),
        open_func = null,
    };

    public static API.Place place_messages = new API.Place () {
        icon = "mail-mailbox-symbolic",
        title = _("Direct Messages"),
        open_func = null,
    };

    public static API.Place place_bookmarks = new API.Place () {
        icon = "user-bookmark-symbolic",
        title = _("Bookmarks"),
        open_func = null,
    };

    public static API.Place place_favorites = new API.Place () {
        icon = "emblem-favorite-symbolic",
        title = _("Favorites"),
        open_func = null,
    };

    public static API.Place place_lists = new API.Place () {
        icon = "text-x-generic-symbolic",
        title = _("Lists"),
        open_func = null,
    };

    public static API.Place place_explore = new API.Place () {
        icon = "location-active",
        title = _("Explore"),
        open_func = null,
    };

    public static API.Place place_local = new API.Place () {
        icon = "drive-harddisk-symbolic",
        title = _("Local"),
        open_func = null,
    };

    public static API.Place place_federated = new API.Place () {
        icon = "network-workgroup-symbolic",
        title = _("Federated"),
        open_func = null,
    };

    public static API.Place place_follow_requests = new API.Place () {
        icon = "contact-new-symbolic",
        title = _("Follow Requests"),
        open_func = null,
    };

    public static API.Place place_hashtags = new API.Place () {
        icon = "system-search-symbolic",
        title = _("Hashtags"),
        open_func = null,
    };

    public static API.Place place_announcements = new API.Place () {
        icon = "x-office-presentation-symbolic",
        title = _("Announcements"),
        open_func = null,
    };

    public override void register_known_places (ListStore places) {
        places.append (place_home);
        places.append (place_explore);
        places.append (place_local);
        places.append (place_federated);
        places.append (place_favorites);
        places.append (place_bookmarks);
        places.append (place_lists);
        places.append (place_hashtags);
        places.append (place_follow_requests);
        places.append (place_announcements);
    }
}
