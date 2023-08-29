public class Pachy.Widgets.EmojiLabel : Internal.Widgets.LabelWithWidgets {
    // TODO: Label with Widgets handle emojis, for now this is just a wrapper around a regular label
    public Gee.HashMap<string, string>? instance_emojis { get; set; default = null; }
    public string content {
        get { return text; }
        set { text = value; }
    }

    public EmojiLabel (string? text = null, Gee.HashMap<string, string>? emojis = null) {
        Object ();
        if (text == null) {
            return;
        }
        content = text;
    }
}
