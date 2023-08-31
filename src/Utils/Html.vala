public class Pachy.HtmlUtils {
    public static string replace_with_pango_markup (string str) {
        var res = str
            .replace ("<strong>", "<b>")
            .replace ("</strong>", "</b>")
            .replace ("<em>", "<i>")
            .replace ("</em>", "</i>")
            .replace ("<del>", "<s>")
            .replace ("</del>", "</s>");
        if ("<br>" in str) {
            res = res.replace ("\n", "");
        }
        return res;
    }
}
