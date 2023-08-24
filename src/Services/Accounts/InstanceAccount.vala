public class Pachy.Services.Accounts.InstanceAccount : API.Account {
    public const string EVENT_NEW_POST = "update";
    public const string EVENT_EDIT_POST = "status.update";
    public const string EVENT_DELETE_POST = "delete";
    public const string EVENT_NOTIFICATION = "notification";
    public const string EVENT_CONVERSATION = "conversation";

    public const string KIND_MENTION = "mention";
    public const string KIND_REBLOG = "reblog";
    public const string KIND_FAVORITE = "favorite";
    public const string KIND_FOLLOW = "follow";
    public const string KIND_POLL = "poll";
    public const string KIND_FOLLOW_REQUEST = "follow_request";
    public const string KIND_REMOTE_REBLOG = "__remote-reblog";
    public const string KIND_EDITED = "update";

    public string? backend { get; set; }
    public string? instance { get; set; }
    public string? client_id { get; set; }
    public string? client_secret { get; set; }
    public string? client_access_token { get; set; }
    public string? user_access_token { get; set; }

    public new string handle_short {
        owned get { return @"@$username"; }
    }

    public new string handle {
        owned get { return full_handle; }
    }

    public bool is_active {
        get {
            if (accounts.active == null) {
                return false;
            }
            return accounts.active.user_access_token == user_access_token;
        }
    }

    public virtual signal void activated ();
    public virtual signal void deactivated ();
    public virtual signal void added ();
    public virtual signal void removed ();

    public InstanceAccount.empty (string instance) {
        Object (
            id: "",
            instance: instance
        );
    }

    public async void verify_credentials () throws Error {
        var req = new Services.Network.Request.GET ("/api/v1/accounts/verify_credentials")
            .with_account (this);
        yield req.await ();

        update_object (req.response_body);
    }

    public void update_object (InputStream in_stream) throws Error {
        var parser = Network.Network.get_parser_from_inputstream (in_stream);
        var node = network.parse_node (parser);
        var updated = API.Account.from (node);
        patch (updated);

        message (@"$handle: profile updated");
    }
}