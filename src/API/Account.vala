public class Pachy.API.Account : Entity, Widgetizable {
    public string id { get; set; }
    public string username { get; set; }
    public string acct { get; set; }
    private string _display_name = "";
    public string display_name {
        get { return ((_display_name != null && _display_name.length > 0) ? _display_name : username); }
        set { _display_name = value; }
    }
    public string note { get; set; }
    public bool locked { get; set; }
    public string header { get; set; }
    public string avatar { get; construct set; }
    public string url { get; set; }
    public bool bot { get; set; default = false; }
    public string created_at { get; set; }
    public Gee.ArrayList<Emoji>? emojis { get; set; }
    public int64 followers_count { get; set; }
    public int64 following_count { get; set; }

    public string handle {
        owned get {
            return "@" + acct;
        }
    }
    public string domain {
        owned get {
            Uri uri;
            try {
                uri = Uri.parse (url, UriFlags.NONE);
            } catch (UriError e) {
                warning (e.message);
                return "";
            }
            return uri.get_host ();
        }
    }
    public string full_handle {
        owned get {
            return @"@$username@$domain";
        }
    }
    public Gee.HashMap<string, string>? emojis_map {
        owned get {
            return gen_emojis_map ();
        }
    }

    private Gee.HashMap<string, string>? gen_emojis_map () {
        var res = new Gee.HashMap<string, string> ();
        if (emojis != null && emojis.size > 0) {
            emojis.@foreach ( e => {
                res.set (e.shortcode, e.url);
                return true;
            });
        }
        return res;
    }

    public static Account from (Json.Node node) throws Error {
        return Entity.from_json (typeof (API.Account), node) as API.Account;
    }

    public override bool is_local (Services.Accounts.InstanceAccount account) {
        return account.domain in url;
    }
}
