/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public class Byte : Gtk.Application {
    public MainWindow main_window;

    public static Byte _instance = null;
    public static Byte instance {
        get {
            if (_instance == null) {
                _instance = new Byte ();
            }
            return _instance;
        }
    }

    private static bool n_version = false;
	private static bool clear_database = false;
	private static string lang = "";

    private const OptionEntry[] OPTIONS = {
		{ "version", 'v', 0, OptionArg.NONE, ref n_version, "Display version number", null },
		{ "reset", 'r', 0, OptionArg.NONE, ref clear_database, "Reset Planify", null },
		{ "lang", 'l', 0, OptionArg.STRING, ref lang, "Open Planify in a specific language", "LANG" },
		{ null }
	};

    public Byte () {
        Object (
            application_id: "io.github.ellie_commons.byte",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);
        
        add_main_option_entries (OPTIONS);
        create_dir_with_parents ("/io.github.ellie_commons.byte");
        create_dir_with_parents ("/io.github.ellie_commons.byte/covers");
    }

    protected override void startup () {
        base.startup ();

        Granite.init ();

        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (quit);
        add_action (quit_action);
        
        set_accels_for_action ("app.quit", { "<Control>q" });

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme =
            granite_settings.prefers_color_scheme == DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme =
                granite_settings.prefers_color_scheme == DARK;
        });
    }

    protected override void activate () {
        if (lang != "") {
			GLib.Environment.set_variable ("LANGUAGE", lang, true);
		}

		if (n_version) {
			print ("Version: %s\n".printf (VERSION));
			return;
		}

		if (clear_database) {
			stdout.printf (_("Are you sure you want to reset all? (y/n): "));
			string? option = stdin.read_line ();

			if (option.down () == _("y") || option.down () == _("yes")) {
			    Services.Database.instance ().clear_database ();
				return;
			}
		}

        if (main_window != null) {
            main_window.present ();
            return;
        }

        var main_window = new MainWindow (this);

        Services.Settings.instance ().settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
        Services.Settings.instance ().settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/github/ellie_commons/byte/application.css");

        Gtk.StyleContext.add_provider_for_display (
                                                   Gdk.Display.get_default (),
                                                   provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        main_window.present ();

        var indicator = new Services.Indicator ();
        indicator.initialize ();
    }

    public void create_dir_with_parents (string dir) {
        string path = Environment.get_user_data_dir () + dir;
        File tmp = File.new_for_path (path);
        if (tmp.query_file_type (0) != FileType.DIRECTORY) {
            GLib.DirUtils.create_with_parents (path, 0775);
        }
    }

    public static int main (string[] args) {
        Gst.init (ref args);
        Byte app = Byte.instance;
        return app.run (args);
    }
}
