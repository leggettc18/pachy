public errordomain Pachy.Services.Network.NetworkError {
    INSTANCE,
}

public class Pachy.Services.Network.Request : Object {
    private Soup.Message _msg;
    public Soup.Message msg {
        get { return _msg; }
        set {
            if (cancellable != null && !cancellable.is_cancelled ()) {
                cancellable.cancel ();
            }
            _msg = value;
            cancellable = new Cancellable ();
        }
    }
    public string url { get; construct set; }
    public Soup.MessagePriority priority { get; set; }
    private string _method;
    public string method {
        get { return msg == null ? _method : msg.method; }
        construct set {
            _method = value;
            if (msg != null) {
                msg.method = value;
            }
        }
    }
    public InputStream response_body { get; set; }
    public weak Accounts.InstanceAccount? account { get; set; default = null; }
    Network.SuccessCallback? cb;
    Network.ErrorCallback? error_cb;
    Gee.HashMap<string, string>? pars;
    Soup.Multipart? form_data;
    public Cancellable cancellable { get; set; }

    weak Gtk.Widget? ctx;
    bool has_ctx = false;

    private string? content_type = null;
    private Bytes? body_bytes = null;

    public Request.GET (string url) {
        Object (url: url, method: "GET");
    }

    public Request.POST (string url) {
        Object (url: url, method: "POST");
    }

    public Request.PUT (string url) {
        Object (url: url, method: "PUT");
    }

    public Request.DELETE (string url) {
        Object (url: url, method: "DELETE");
    }

    public Request.PATCH (string url) {
        Object (url: url, method: "PATCH");
    }

    private Request () {
        Object (url: "", method: "GET");
    }

    construct {
        msg = new Soup.Message (method, url);
    }

    public void set_request_body_from_bytes (string? t_content_type, Bytes? t_bytes) {
        content_type = t_content_type;
        body_bytes = t_bytes;
    }

    public Request then (owned Network.SuccessCallback cb) {
        this.cb = (owned) cb;
        return this;
    }

    public Request then_parse_array (owned Network.NodeCallback _cb) {
        this.cb = (sess, msg, in_stream) => {
            var parser = Network.get_parser_from_inputstream (in_stream);
            Network.parse_array (msg, parser, (owned) _cb);
        };
        return this;
    }

    public Request with_ctx (Gtk.Widget ctx) {
        this.has_ctx = true;
        this.ctx = ctx;
        this.ctx.destroy.connect (() => {
            this.cancellable.cancel ();
            this.ctx = null;
        });
        return this;
    }

    public Request on_error (owned Network.ErrorCallback cb) {
        this.error_cb = (owned) cb;
        return this;
    }

    public Request with_account (Accounts.InstanceAccount? account = null) {
        this.account = account;
        return this;
    }

    public Request with_param (string name, string val) {
        if (pars == null) {
            pars = new Gee.HashMap<string, string> ();
        }
        pars[name] = val;
        return this;
    }

    public Request with_form_data (string name, string val) {
        if (form_data == null) {
            form_data = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
        }
        form_data.append_form_string (name, val);
        return this;
    }

    public Request with_form_data_file (string name, string mime, Bytes buffer) {
        if (form_data == null) {
            form_data = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
        }
        form_data.append_form_file (name, mime.replace ("/", "."), mime, buffer);
        return this;
    }

    public Request body (string? t_content_type, Bytes? t_bytes) {
        content_type = t_content_type;
        body_bytes = t_bytes;
        return this;
    }

    public Request body_json (Json.Builder t_builder) {
        var generator = new Json.Generator ();
        generator.set_root (t_builder.get_root ());
        return body ("application/json", new Bytes.take (generator.to_data (null).data));
    }

    public Request exec () {
        var parameters = "";
        if (pars != null) {
            if ("?" in url) {
                parameters = "&";
            } else {
                parameters = "?";
            }

            var paramters_counter = 0;
            pars.@foreach (entry => {
                paramters_counter++;
                var key = (string) entry.key;
                var val = Uri.escape_string ((string) entry.value);
                parameters += @"$key=$val";

                if (paramters_counter < pars.size) {
                    parameters += "&";
                }

                return true;
            });
        }

        if (!("://" in url)) {
            url = account.instance + url;
        }

        if (msg == null) {
            msg = new Soup.Message (method, url);
        }

        if (form_data != null) {
            var t_method = msg.method;
            msg = new Soup.Message.from_multipart (url, form_data);
            msg.method = t_method;
        } else {
            Uri t_uri;
            try {
                t_uri = Uri.parse (url + parameters, UriFlags.ENCODED_PATH | UriFlags.ENCODED_QUERY);
            } catch (UriError e) {
                warning (e.message);
                return this;
            }
            msg.uri = t_uri;
        }

        if (account != null && account.user_access_token != null) {
            msg.request_headers.remove ("Authorization");
            msg.request_headers.append ("Authorization", @"Bearer $(account.user_access_token)");
        }

        msg.priority = priority;

        if (content_type != null && body_bytes != null) {
            msg.set_request_body_from_bytes (content_type, body_bytes);
        }

        network.queue (msg, this.cancellable, (owned) cb, (owned) error_cb);
        return this;
    }

    public async Request await () throws Error {
        string? error = null;
        this.error_cb = (code, reason) => {
            error = reason;
            await.callback ();
        };
        this.cb = (sess, msg, in_stream) => {
            this.response_body = in_stream;
            await.callback ();
        };
        this.exec ();
        yield;

        if (error != null) {
            throw new NetworkError.INSTANCE (error);
        } else {
            return this;
        }
    }

    public static string array_to_string (Gee.ArrayList<string> array, string key) {
        var result = "";
        array.@foreach (i => {
            result += @"$key[]=$i";
            if (array.index_of (i) + 1 != array.size) {
                result += "&";
            }
            return true;
        });
        return result;
    }
}
