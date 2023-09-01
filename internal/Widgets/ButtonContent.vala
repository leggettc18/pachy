public class Pachy.Internal.Widgets.ButtonContent : Gtk.Box {
    private Gtk.Label _label;
    private Gtk.Image _icon;

    public string label {
        get { return _label.label; }
        set { _label.label = value; }
    }

    public string icon_name {
        owned get { return _icon.icon_name; }
        set { _icon.icon_name = value; }
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 6;
        _icon = new Gtk.Image ();
        _label = new Gtk.Label (null);
        append (_icon);
        append (_label);
    }
}
