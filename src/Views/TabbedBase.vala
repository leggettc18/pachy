public class Pachy.Views.TabbedBase : Base {
    static int id_counter = 0;

    protected Gtk.StackSwitcher switcher = new Gtk.StackSwitcher ();
    protected Gtk.Stack stack;

    Base? last_view = null;
    Base[] views = {};

    construct {
        base_status = null;

        scrolled_overlay.child = null;
        var scrolled_overlay_box = scrolled_overlay.get_parent () as Gtk.Box;
        if (scrolled_overlay_box != null) {
            scrolled_overlay_box.remove (scrolled_overlay);
        }
        insert_child_after (states, header);

        stack = new Gtk.Stack ();
        stack.notify["visible-child"].connect (on_view_switched);
        scrolled.child = stack;
        switcher.stack = stack;
    }

    ~TabbedBase () {
        message ("Destroying TabbedBase");

        foreach (var tab in views) {
            stack.remove (tab);
            tab.dispose ();
        }
        views = {};
    }

    public override void build_header () {
        base.build_header ();
        header.title_widget = switcher;
    }

    public void add_tab (Base view) {
        id_counter ++;
        view.content_box.add_css_class ("no-transition");
        views += view;
        var page = stack.add_titled (view, id_counter.to_string (), view.label);
        view.bind_property ("icon", page, "icon-name", BindingFlags.SYNC_CREATE);
        view.bind_property ("needs-attention", page, "needs-attention", BindingFlags.SYNC_CREATE);
        //view.bind_property ("badge-number", page, "badge-number", BindingFlags.SYNC_CREATE);
        view.header.hide ();
    }

    private void on_view_switched () {
        var view = stack.visible_child as Views.Base;
        if (view.content_box.has_css_class ("no-transition")) {
            Timeout.add_once (200, () => {
                last_view.content_box.remove_css_class ("no-transition");
            });
        }

        if (last_view != null) {
            last_view.current = false;
        }

        if (view != null) {
            label = view.label;
            view.current = true;
        }

        last_view = view;
    }
}
