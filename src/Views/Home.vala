public class Pachy.Views.Home : Timeline {
    construct {
        url = "/api/v1/timelines/home";
        label = _("Home");
        icon = "user-home-symbolic";
    }

    public override string? get_stream_url () {
        return account != null
            ? @"$(account.instance)/api/v1/streaming/?stream=user&access_token=$(account.user_access_token)"
            : null;
    }
}
