/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public class MainWindow : Gtk.ApplicationWindow {
    private Views.Welcome welcome_view;
    private Adw.NavigationView navigation_view;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            width_request: 300,
            height_request: 480,
            icon_name: "io.github.ellie_commons.byte",
            title: "Byte"
        );
    }

    static construct {
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        default_theme.add_resource_path ("/io/github/ellie_commons/byte/");
    }

    construct {
        var headerbar = new Gtk.HeaderBar () {
            decoration_layout = "close:menu"
        };
        headerbar.add_css_class ("primary-headerbar");

        var sidebar_button = new Gtk.Button.from_icon_name ("view-dual-symbolic");
        headerbar.pack_end (sidebar_button);

        welcome_view = new Views.Welcome ();
        navigation_view = new Adw.NavigationView ();
        
        var toolbar_view = new Adw.ToolbarView () {
            content = navigation_view
        };
        toolbar_view.add_top_bar (headerbar);

        var sidebar = new Widgets.Sidebar ();

        var overlay_split_view = new Adw.OverlaySplitView () {
            collapsed = true,
            sidebar_position = END,
            min_sidebar_width = 225,
            max_sidebar_width = 225,
            content = toolbar_view,
            sidebar = sidebar
        };

        var null_title = new Gtk.Grid () {
            visible = false
        };
        set_titlebar (null_title);

        child = overlay_split_view;

        Timeout.add_once (250, () => {
            init_backend ();
        });

        welcome_view.selected.connect ((index) => {
            init_sync.begin (index);
        });

        sidebar_button.clicked.connect (() => {
            overlay_split_view.show_sidebar = true;
        });

        Services.EventBus.instance ().select_view.connect ((view_type) => {
            if (view_type == ViewType.HOME) {
                add_home_view ();
            }

            overlay_split_view.show_sidebar = false;
        });
    }

    private async void init_sync (int index) {
        string folder;
        if (index == 0) {
            folder = "file://" + GLib.Environment.get_user_special_dir (GLib.UserDirectory.MUSIC);
        } else {
            folder = yield choose_folder ();
        }

        if (folder == null) {
            return;
        }

        Services.Scanner.instance ().scan_local_files (folder);
        //  Byte.settings.set_string ("library-location", folder);
    }

    private async string? choose_folder () {
        var dialog = new Gtk.FileDialog ();

        try {
            var file = yield dialog.select_folder (this, null);
            return file.get_uri ();
        } catch (Error e) {
            debug ("Error during import backup: %s".printf (e.message));
        }

        return null;
    }

    private void init_backend () {
        Services.Database.instance ().init_database ();

        if (Services.Library.instance ().is_empty ()) {
            navigation_view.add (new Adw.NavigationPage (welcome_view, _("Welcome")));
            return;
        }

        Services.EventBus.instance ().select_view (ViewType.HOME);
    }

    private void add_home_view () {
        
    }
}
