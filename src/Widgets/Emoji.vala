public class Pachy.Widgets.Emoji : Gtk.Widget {
    protected Gtk.Image image;
    public string? shortcode { get; set; }
    public int pixel_size {
        get { return image.pixel_size; }
        set { image.pixel_size = value; }
    }
    public Gtk.IconSize icon_size {
        get { return image.icon_size; }
        set { image.icon_size = value; }
    }

    construct {
        layout_manager = new Gtk.BinLayout ();
        image = new Gtk.Image.from_icon_name ("image-loading") {
            hexpand = true,
            vexpand = true,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            css_classes = { "lww-emoji" }
        };
        image.set_parent (this);
    }

    public Emoji (string emoji_url, string? t_shortcode = null) {
        if (t_shortcode != null) {
            image.tooltip_text = t_shortcode;
            shortcode = t_shortcode;
        }

        Idle.add (() => {
            image_cache.request_paintable (emoji_url, on_cache_response);
            return Source.REMOVE;
        });
    }

    ~Emoji () {
        image.unparent ();
        image.destroy ();
    }

    void on_cache_response (bool is_loaded, owned Gdk.Paintable? data) {
        if (image != null) {
            image.paintable = data;
        }
    }
}
