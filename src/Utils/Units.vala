public class Pachy.Utils.Units {
    public enum ShortUnitType {
        NONE,
        THOUSAND,
        MILLION,
        BILLION;

        public string to_string () {
            switch (this) {
                case THOUSAND:
                    return _("k");
                case MILLION:
                    return _("M");
                case BILLION:
                    return _("G");
                default:
                    return "";
            }
        }
    }

    public struct ShortUnit {
        int64 top;
        ShortUnitType symbol;
    }

    public const ShortUnit[] SHORT_UNITS = {
        { 1000, ShortUnitType.NONE },
        { 1000000, ShortUnitType.THOUSAND },
        { 1000000000, ShortUnitType.MILLION },
        { 1000000000000, ShortUnitType.BILLION }
    };

    public static string shorten (int64 unit) {
        if (unit == 0 || (unit < 0 && unit > -1000) || (unit > 0 && unit < 1000)) {
            return unit.to_string ();
        }
        bool is_negative = unit < 0;
        if (is_negative) {
            unit = unit * -1;
        }
        for (var i = 1; i < SHORT_UNITS.length; i++) {
            var short_unit = SHORT_UNITS[i];
            if (unit >= short_unit.top) {
                continue;
            }
            var shortened_unit = "%.1f".printf (
                Math.trunc (((double) unit / SHORT_UNITS[i - 1].top) * 10.0) / 10.0
            );
            if (shortened_unit.has_suffix ("0") || shortened_unit.length > 3) {
                shortened_unit = shortened_unit.slice (0, shortened_unit.length - 2);
            }
            return @"$(is_negative ? "-" : "")$shortened_unit$(short_unit.symbol)";
        }
        return "∞";
    }
}
