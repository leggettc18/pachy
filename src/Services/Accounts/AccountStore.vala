public errordomain Pachy.Services.Accounts.AccountStoreError {
    BACKEND,
}

public abstract class Pachy.Services.Accounts.AccountStore : Object {
    public Gee.ArrayList<InstanceAccount> saved { get; set; default = new Gee.ArrayList<InstanceAccount> (); }
    public InstanceAccount? active { get; set; default = null; }

    public signal void changed (Gee.ArrayList<InstanceAccount> accounts);
    public signal void switched (InstanceAccount? account);

    public bool ensure_active_account () {
        var has_active = false;
        var account = find_by_handle (settings.active_account);
        if (account == null && !saved.is_empty) {
            account = saved[0];
        }
        has_active = account != null;
        activate (account);

        if (!has_active) {
            app.present_window (true);
        }

        return has_active;
    }

    public virtual void init () throws Error {
        Mastodon.Account.register (this);

        load ();
        ensure_active_account ();
    }

    public abstract void load () throws Error;
    public abstract void save () throws Error;
    public void safe_save () {
        try {
            save ();
        } catch (Error e) {
            warning (e.message);
            // TODO: Present Error Dialog
        }
    }

    public virtual void add (InstanceAccount account) throws Error {
        message (@"Adding new account: $(account.handle)");
        saved.add (account);
        changed (saved);
        save ();
        ensure_active_account ();
    }

    public virtual void remove (InstanceAccount account) throws Error {
        message (@"Removing account: $(account.handle)");
        account.removed ();
        saved.remove (account);
        changed (saved);
        save ();
        ensure_active_account ();
    }

    public InstanceAccount? find_by_handle (string handle) {
        var iter = saved.filter (acc => {
            return acc.handle == handle;
        });
        iter.next ();

        if (!iter.valid) {
            return null;
        } else {
            return iter.@get ();
        }
    }

    public void activate (InstanceAccount? account) {
        if (active != null) {
            active.deactivated ();
        }

        if (account == null) {
            message ("Reset active account");
            return;
        } else {
            message (@"Activating $(account.handle)…");
            account.verify_credentials.begin ((obj, res) => {
                try {
                    account.verify_credentials.end (res);
                    settings.active_account = account.handle;
                    // TODO: handle account.source
                } catch (Error e) {
                    warning (@"Couldn't activate account $(account.handle):");
                    warning (e.message);
                }
            });
        }

        accounts.active = account;
        active.activated ();
        switched (active);
    }

    [Signal (detailed = true)]
    public signal InstanceAccount? create_for_backend (Json.Node node);

    public InstanceAccount create_account (Json.Node node) throws Error {
        var obj = node.get_object ();
        var backend = obj.get_string_member ("backend");
        var handle = obj.get_string_member ("handle");
        var account = create_for_backend[backend] (node);
        if (account == null) {
            throw new AccountStoreError.BACKEND (@"Account $handle has unknown backend: $backend");
        }
        return account;
    }

    public abstract class BackendTest : Object {
        public abstract string? get_backend (Json.Object obj);
    }

    public Gee.ArrayList<BackendTest> backend_tests = new Gee.ArrayList<BackendTest> ();

    public async void guess_backend (InstanceAccount account) throws Error {
        var req = new Network.Request.GET ("/api/v1/instance")
            .with_account (account);
        yield req.await ();

        var parser = Network.Network.get_parser_from_inputstream (req.response_body);
        var root = network.parse (parser);

        string? backend = null;
        backend_tests.foreach (test => {
            backend = test.get_backend (root);
            return true;
        });

        if (backend == null) {
            warning ("This instance is unsupported");
        } else {
            account.backend = backend;
            message (@"$(account.instance) is using $(account.backend)");
        }
    }
}
