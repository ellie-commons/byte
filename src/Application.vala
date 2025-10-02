public class Byte : Gtk.Application {
    public MainWindow main_window;

    public static Services.Database database;
    public static GLib.Settings settings;
    public static Services.Player player;
    public static Services.TagManager tg_manager;
    public static Services.CoverImport cover_import;
    public static Services.Indicator indicator;
    public static Services.Notification notification;
    public static Services.Scan scan_service;
    public static Services.RadioBrowser radio_browser;
    public static Services.Lastfm lastfm_service;
    public static Services.NavController navCtrl;
    public static Utils utils;

    public bool has_entry_focus = false;
    public SimpleAction toggle_playing_action;

    public static Byte _instance = null;
    public static Byte instance {
        get {
            if (_instance == null) {
                _instance = new Byte ();
            }
            return _instance;
        }
    }

    [CCode (array_length = false, array_null_terminated = true)]
    string[] ? arg_files = null;

    public Byte () {
        // Init internationalization support
        Intl.setlocale (LocaleCategory.ALL, "");
        string langpack_dir = Path.build_filename (Constants.INSTALL_PREFIX, "share", "locale");
        Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, langpack_dir);
        Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Constants.GETTEXT_PACKAGE);
        
        // Dir to Database
        utils = new Utils ();
        utils.create_dir_with_parents ("/.local/share/com.github.alainm23.byte");
        utils.create_dir_with_parents ("/.local/share/com.github.alainm23.byte/covers");

        settings = new Settings ("com.github.alainm23.byte");
        player = new Services.Player ();
        database = new Services.Database ();
        tg_manager = new Services.TagManager ();
        cover_import = new Services.CoverImport ();
        notification = new Services.Notification ();
        scan_service = new Services.Scan ();
        radio_browser = new Services.RadioBrowser ();
        lastfm_service = new Services.Lastfm ();
        navCtrl = new Services.NavController ();
    }

    construct {
        this.flags |= ApplicationFlags.HANDLES_OPEN;
        this.flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
        this.application_id = "com.github.alainm23.byte";
    }

    protected override void activate () {
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            return;
        }

        main_window = new MainWindow (this);

        int window_x, window_y;
        var rect = Gtk.Allocation ();

        settings.get ("window-position", "(ii)", out window_x, out window_y);
        settings.get ("window-size", "(ii)", out rect.width, out rect.height);

        if (window_x != -1 || window_y != -1) {
            main_window.move (window_x, window_y);
        }

        main_window.set_allocation (rect);
        main_window.show_all ();

        // Indicator
        indicator = new Services.Indicator ();
        indicator.initialize ();

        // Media Keys
        Services.MediaKey.listen ();

        // Actions
        var quit_action = new SimpleAction ("quit", null);
        set_accels_for_action ("app.quit", {"<Control>q"});

        toggle_playing_action = new SimpleAction ("toggle_playing_action", null);
        set_accels_for_action ("app.toggle_playing_action", {"space"});

        var search_action = new SimpleAction ("search", null);
        set_accels_for_action ("app.search", {"<Control>f"});

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
            }
        });

        toggle_playing_action.activate.connect (() => {
            if (!has_entry_focus) {
                player.toggle_playing ();
            }
        });

        search_action.activate.connect (() => {
            //player.toggle_playing ();
        });

        add_action (quit_action);
        add_action (toggle_playing_action);
        add_action (search_action);

        // Default Icon Theme
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/byte");


        // Stylesheet
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/alainm23/byte/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var theme_id = Byte.settings.get_enum ("theme");
        if (theme_id == 0) {
            utils.auto_apply_theme ();
        } else {
            utils.apply_theme (theme_id);
        }
    }

    public override void open (File[] files, string hint) {
        activate ();
        if (files [0].query_exists ()) {
            main_window.open_file (files [0]);
        }
    }

    public override int command_line (ApplicationCommandLine cmd) {
        command_line_interpreter (cmd);
        return 0;
    }

    private void command_line_interpreter (ApplicationCommandLine cmd) {
        string[] args_cmd = cmd.get_arguments ();
        unowned string[] args = args_cmd;

        bool next = false;
        bool prev = false;
        bool play = false;

        GLib.OptionEntry [] options = new OptionEntry [5];
        options [0] = { "next", 0, 0, OptionArg.NONE, ref next, "Play next track", null };
        options [1] = { "prev", 0, 0, OptionArg.NONE, ref prev, "Play previous track", null };
        options [2] = { "play", 0, 0, OptionArg.NONE, ref play, "Toggle playing", null };
        options [3] = { "", 0, 0, OptionArg.STRING_ARRAY, ref arg_files, null, "[URI…]" };
        options [4] = { null };

        var opt_context = new OptionContext ("actions");
        opt_context.add_main_entries (options, null);
        try {
            opt_context.parse (ref args);
        } catch (Error err) {
            warning (err.message);
            return;
        }

        if (next || prev || play) {
            if (next && main_window != null) {
                Byte.player.next ();
            } else if (prev && main_window != null) {
                Byte.player.prev ();
            } else if (play) {
                if (main_window == null) {
                    activate ();
                }
                Byte.player.toggle_playing ();
            }

            return;
        }

        File[] files = null;
        foreach (string arg_file in arg_files) {
            if (GLib.FileUtils.test (arg_file, GLib.FileTest.EXISTS)) {
                files += (File.new_for_path (arg_file));
            }
        }

        if (files != null && files.length > 0) {
            open (files, "");
            return;
        }

        activate ();
    }

    public void toggle_playing_action_enabled (bool b) {
        if (b) {
            set_accels_for_action ("app.toggle_playing_action", {"space"});
        } else {
            set_accels_for_action ("app.toggle_playing_action", {null});
        }
    }
}

public static int main (string[] args) {
    Gst.init (ref args);
    var app = Byte.instance;
    return app.run (args);
}
