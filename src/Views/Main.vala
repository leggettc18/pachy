public class Pachy.Views.Main : TabbedBase {
    construct {
        is_main = true;

        add_tab (new Home ());
        add_tab (
            new Views.Base () {
                label = "Notifications",
                base_status = new Views.Base.StatusMessage () {
                    message = "Notifications",
                },
            }
        );
        add_tab (
            new Views.Base () {
                label = "Conversations",
                base_status = new Views.Base.StatusMessage () {
                    message = "Conversations",
                },
            }
        );
    }

    public override void build_header () {
        base.build_header ();
        back_button.hide ();
    }
}
