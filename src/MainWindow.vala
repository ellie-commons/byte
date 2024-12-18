/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public class MainWindow : Gtk.ApplicationWindow {
    private Views.Welcome welcome_view;
    private Adw.NavigationView navigation_view;

    private Gee.HashMap<string, Adw.NavigationPage> pages_map = new Gee.HashMap<string, Adw.NavigationPage> ();

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
        welcome_view = new Views.Welcome ();
        
        navigation_view = new Adw.NavigationView () {
            hexpand = true,
            vexpand = true
        };

        var media_control = new Widgets.MediaControl ();

        var media_control_revealer = new Gtk.Revealer () {
            child = media_control,
            valign = END,
            transition_type = SLIDE_UP,
            reveal_child = true
        };

        var overlay = new Gtk.Overlay () {
            child = navigation_view
        };

        overlay.add_overlay (media_control_revealer);

        var sidebar = new Widgets.Sidebar ();

        var overlay_split_view = new Adw.OverlaySplitView () {
            collapsed = true,
            sidebar_position = END,
            min_sidebar_width = 225,
            max_sidebar_width = 225,
            content = overlay,
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

        Services.EventBus.instance ().show_sidebar.connect (() => {
            overlay_split_view.show_sidebar = true;
        });

        Services.EventBus.instance ().select_view.connect ((view_type) => {
            if (view_type == ViewType.HOME) {
                root_view (new Views.Home (), "home", _("Home"));
            } else if (view_type == ViewType.RECENTLY_ADDED) {
                root_view (new Views.RecentlyAdded (), "recently-added", _("Recently Added"));
            } else if (view_type == ViewType.SONGS) {
                root_view (new Views.Tracks (), "tracks", _("Songs"));
            }

            overlay_split_view.show_sidebar = false;
        });

        Services.Scanner.instance ().sync_started.connect (() => {
            //  media_control.reveal_child = true;
        });

        Services.Scanner.instance ().sync_finished.connect (() => {
            //  media_control.reveal_child = false;
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
            navigation_view.replace ({ new Adw.NavigationPage (welcome_view, _("Welcome")) });
            return;
        }

        Services.EventBus.instance ().select_view (ViewType.HOME);
    }

    private void root_view (Gtk.Widget view, string key, string title) {
        Adw.NavigationPage? navigation_page;
        if (pages_map.has_key (key)) {
            navigation_page = pages_map[key];
        } else {
            navigation_page = new Adw.NavigationPage (view, title);
            pages_map.set (key, navigation_page);
        }

        navigation_view.replace ({ navigation_page });
    }
}
