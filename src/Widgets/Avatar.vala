public class Pachy.Widgets.Avatar : Gtk.Button {
    public API.Account? account { get; set; }
    private Pachy.Internal.Widgets.Avatar? avatar {
        get { return child as Pachy.Internal.Widgets.Avatar; }
    }
    public int size {
        get { return avatar.size; }
        set { avatar.size = value; }
    }
    public Gdk.Paintable? custom_image {
        get { return avatar.custom_image; }
    }
    public string? avatar_url { get; set; }

    construct {
        message ("initialzing Avatar Widget");
        child = new Pachy.Internal.Widgets.Avatar (48, null, true);
        message ("created PachyLib Avatar");
        halign = valign = Gtk.Align.CENTER;
        css_classes = {
            Granite.STYLE_CLASS_CIRCULAR,
            Granite.STYLE_CLASS_FLAT,
            "ttl-flat-button",
        };

        message ("setting up signals");
        notify["account"].connect (on_invalidated);
        notify["avatar-url"].connect (on_avatar_url_change);
        on_invalidated ();
        message ("initialized Avatar Widget");
    }

    private void on_avatar_url_change () {
        if (avatar_url == null) {
            return;
        }

        image_cache.request_paintable (avatar_url, on_cache_response);
    }

    private void on_invalidated () {
        if (account == null) {
            avatar.text = "";
            avatar.show_initials = false;
        } else {
            avatar.text = account.display_name;
            avatar.show_initials = true;
            image_cache.request_paintable (account.avatar, on_cache_response);
        }
    }

    private void on_cache_response (bool is_loaded, owned Gdk.Paintable? data) {
        avatar.custom_image = data;
    }
}
