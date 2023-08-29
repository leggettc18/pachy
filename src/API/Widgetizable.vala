public interface Pachy.API.Widgetizable : Object {
    public virtual Gtk.Widget to_widget () throws PachyError {
        throw new PachyError.INTERNAL ("Widgetizable doesn't provide a widget");
    }

    public virtual void open () {
        warning ("Widgetizable doesn't provide a way to open it!");
    }

    public virtual void resolve_open (Services.Accounts.InstanceAccount account) {
        this.open ();
    }
}
