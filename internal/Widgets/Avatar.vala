public class PachyLib.Widgets.Avatar : Gtk.Widget {
    private const int NUMBER_OF_COLORS = 14;

    private Gtk.Label _label;
    private Gtk.Image _icon;
    private Gtk.Image _image;
    private Gdk.Paintable? _custom_image = null;
    private int _size;
    private string _text;
    private bool _show_initials;
    private string _icon_name;
    private uint _color_class;

    public string icon_name {
        get { return _icon_name; }
        set {
            if (value == _icon_name) {
                return;
            }

            _icon_name = value;
            update_icon ();
        }
    }
    public string text {
        get { return _text; }
        set {
            if (value == _text) {
                return;
            }
            _text = value;

            set_class_color ();
            update_initials ();
            update_font_size ();
            update_visibility ();
        }
    }
    public int size {
        get { return _size; }
        set {
            if (_size == value) {
                return;
            }

            _size = value;
            set_size_request (value, value);
            _icon.pixel_size = value / 2;

            if (_size < 25) {
                add_css_class ("contrasted");
            } else {
                remove_css_class ("contrasted");
            }

            update_font_size ();
            update_custom_image_snapshot ();
            queue_resize ();
        }
    }
    public Gdk.Paintable custom_image {
        get { return _custom_image; }
        set {
            if (_custom_image == value) {
                return;
            }
            _custom_image = value;

            if (value != null) {
                int height = value.get_intrinsic_height ();
                int width = value.get_intrinsic_width ();

                update_custom_image_snapshot ();

                if (height != width && !(value.get_type () == typeof (Gdk.Texture))) {
                    Signal.connect_swapped (
                        _custom_image,
                        "invalidate-contents",
                        (Callback) update_custom_image_snapshot,
                        this
                    );
                }
                add_css_class ("image");
            } else {
                _image = new Gtk.Image.from_paintable (null);
                remove_css_class ("image");
            }

            update_initials ();
            update_visibility ();
        }
    }
    public bool show_initials {
        get { return _show_initials; }
        set {
            if (value == _show_initials) {
                return;
            }

            _show_initials = value;

            update_initials ();
            update_font_size ();
            update_visibility ();
        }
    }

    public Avatar (int size, string? text, bool show_initials) {
        Object (size: size, text: text, show_initials: show_initials);
    }

    class construct {
        set_css_name ("avatar");
    }

    construct {
        overflow = Gtk.Overflow.HIDDEN;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        layout_manager = new Gtk.BinLayout ();

        _label = new Gtk.Label ("");
        _label.set_parent (this);

        _icon = new Gtk.Image ();
        _icon.set_parent (this);

        _image = new Gtk.Image ();
        _image.set_parent (this);

        set_class_color ();
        update_initials ();
        update_font_size ();
        update_icon ();
        update_visibility ();

        notify["root"].connect (update_font_size);
        notify["scale-factor"].connect (update_custom_image_snapshot);
    }

    private void update_custom_image_snapshot () {
        Gtk.Snapshot? snapshot = null;
        Gdk.Paintable square_image;
        int width, height;
        float scaled_width, scaled_height;
        float size;

        if (_custom_image == null) {
            return;
        }

        width = _custom_image.get_intrinsic_width ();
        height = _custom_image.get_intrinsic_height ();

        if (height == width && !(_custom_image.get_type () == typeof (Gdk.Texture))) {
            _image.paintable = _custom_image;
            return;
        }

        size = _size * scale_factor;

        if (width > height) {
            scaled_height = size;
            scaled_width = (float) width * scaled_height / (float) height;
        } else if (width < height) {
            scaled_width = size;
            scaled_height = (float) height * scaled_width / (float) width;
        } else {
            scaled_width = scaled_height = size;
        }

        snapshot = new Gtk.Snapshot ();
        snapshot.translate (Graphene.Point.zero ().init ((size - scaled_width) / 2.0f, (size - scaled_height) / 2.0f));

        if (_custom_image.get_type () == typeof (Gdk.Texture)) {
            Gsk.ScalingFilter filter;
            if (scaled_width > width || scaled_height > height) {
                filter = Gsk.ScalingFilter.NEAREST;
            } else {
                filter = Gsk.ScalingFilter.TRILINEAR;
            }
            snapshot.append_scaled_texture (
                _custom_image as Gdk.Texture,
                filter,
                Graphene.Rect.zero ().init (0, 0, scaled_width, scaled_height)
            );
        } else {
            _custom_image.snapshot (snapshot, scaled_width, scaled_height);
        }

        square_image = snapshot.free_to_paintable (Graphene.Size.zero ().init (size, size));
        _image.paintable = square_image;
    }

    private void update_font_size () {
        int width, height;
        double padding;
        double sqr_size;
        double max_size;
        double new_font_size;
        Pango.AttrList attributes;

        if (_image.paintable != null || !_show_initials || _text == null || _text.length == 0) {
            return;
        }

        attributes = new Pango.AttrList ();
        _label.attributes = attributes;
        _label.get_layout ().get_pixel_size (out width, out height);

        sqr_size = (double) _size / 1.4142;
        padding = Math.fmax (_size * 0.4 - 5, 0);
        max_size = sqr_size - padding;
        new_font_size = (double) height * (max_size / (double) width);

        attributes.change (Pango.AttrSize.new_absolute ((int) new_font_size.clamp (0, max_size) * Pango.SCALE));
        _label.attributes = attributes;
    }

    private void update_icon () {
        if (_icon_name != null) {
            _icon.icon_name = _icon_name;
        } else {
            _icon.icon_name = "avatar-default-symbolic";
        }
    }

    private string? extract_initials_from_text (string text) {
        string initials;
        string p = text.up ();
        string normalized = p.strip ().normalize (-1, GLib.NormalizeMode.DEFAULT_COMPOSE);
        string q = null;

        if (normalized == null) {
            return null;
        }

        initials = "";
        unichar char = normalized.get_char ();
        initials = initials + char.to_string ();
        q = normalized.substring (normalized.last_index_of_char (' '));
        if (q != null) {
            char = q.next_char ().get_char ();
            if (char != 0) {
                initials = initials + char.to_string ();
            }
        }
        return initials;
    }

    private void update_initials () {
        string initials;
        if (_image.paintable != null || !_show_initials || _text == null || _text.length == 0) {
            return;
        }
        initials = extract_initials_from_text (_text);
        _label.label = initials;
    }

    private void update_visibility () {
        bool has_custom_image = _image.paintable != null;
        bool has_initials = _show_initials && _text != null && _text.length > 0;

        _label.visible = !has_custom_image && has_initials;
        _icon.visible = !has_custom_image && !has_initials;
        _image.visible = has_custom_image;
    }

    private void set_class_color () {
        string old_class, new_class;
        old_class = "color%u".printf (_color_class);
        remove_css_class (old_class);
        if (_text == null || _text.length == 0) {
            Rand rand = new Rand ();
            _color_class = rand.int_range (1, NUMBER_OF_COLORS);
        } else {
            _color_class = (_text.hash () % NUMBER_OF_COLORS) + 1;
        }
        new_class = "color%u".printf (_color_class);
        debug (new_class);
        add_css_class (new_class);
    }
}
