public class Pachy.API.Visibility : Object {
    public string id { get; construct set; }
    public string name { get; construct set; }
    public string icon_name { get; construct set; }
    public string description { get; construct set; }

    private string? _small_icon_name = null;
    public string small_icon_name {
        get { return _small_icon_name ?? icon_name; }
        set { _small_icon_name = value; }
    }
}
