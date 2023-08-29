public class Pachy.Internal.Widgets.LabelWithWidgets: Gtk.Widget {
    private Gtk.Label label;

    public string text {
        get { return label.label; }
        set {
            label.label = value;
            label.notify_property ("label");
        }
    }

    construct {
        layout_manager = new Gtk.BinLayout ();
        label = new Gtk.Label ("") {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            xalign = 0.0f,
            valign = Gtk.Align.START,
        };
        label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);
        label.set_parent (this);
    }

    ~LabelWithWidgets () {
        label.unparent ();
    }
}
