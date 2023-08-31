public interface Pachy.API.AccountHolder : Object {
    protected abstract Services.Accounts.InstanceAccount? account { get; set; default = null; }

    protected void construct_account_holder () {
        accounts.switched.connect (on_account_changed);
        accounts.changed.connect (on_accounts_changed);
        on_account_changed (accounts.active);
        on_accounts_changed (accounts.saved);
    }

    protected void destruct_account_holder () {
        accounts.switched.disconnect (on_account_changed);
        accounts.changed.disconnect (on_accounts_changed);
    }

    protected virtual void on_account_changed (Services.Accounts.InstanceAccount? account) {
        this.account = account;
    }

    protected virtual void on_accounts_changed (Gee.ArrayList<Services.Accounts.InstanceAccount> accounts) {}
}
