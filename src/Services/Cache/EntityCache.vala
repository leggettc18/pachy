public class Pachy.Services.Cache.EntityCache : AbstractCache {
    protected string? get_node_cache_id (owned Json.Node node) {
        var obj = node.get_object ();
        if (obj.has_member ("uri")) {
            return obj.get_string_member ("uri");
        }
        return null;
    }

    public API.Entity lookup_or_insert (owned Json.Node node, owned Type type, bool force = false) {
        API.Entity entity = null;
        var id = get_node_cache_id (node);

        if (id == null) {
            try {
                entity = API.Entity.from_json (type, node);
            } catch (Error e) {
                warning (@"Error getting Entity from json: $(e.message)");
            }
        } else {
            if (!force && contains (id)) {
                entity = lookup (get_key (id)) as API.Entity;
                message (@"Reused: $id");
            } else {
                try {
                    entity = API.Entity.from_json (type, node);
                } catch (Error e) {
                    warning (@"Error getting Entity from json: $(e.message)");
                }
                insert (id, entity);
            }
        }
        return entity;
    }
}
