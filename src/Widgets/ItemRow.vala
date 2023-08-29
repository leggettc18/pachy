public class Pachy.Widgets.ItemRow : Gtk.ListBoxRow {
    public API.Place place { get; construct; }

    private Gtk.Image icon;
    private Gtk.Label label;
    private Gtk.Box box;

    public ItemRow (API.Place place) {
        Object (place: place);
        place.bind_property ("title", label, "label", BindingFlags.SYNC_CREATE);
        place.bind_property ("icon", icon, "icon-name", BindingFlags.SYNC_CREATE);
        place.bind_property ("selectable", this, "selectable", BindingFlags.SYNC_CREATE);
    }

    construct {
        icon = new Gtk.Image ();
        label = new Gtk.Label ("");
        box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.append (icon);
        box.append (label);
        child = box;
    }
}
