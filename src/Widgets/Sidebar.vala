/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.Sidebar : Adw.Bin {
    construct {
        var headerbar = new Gtk.HeaderBar () {
            title_widget = new Gtk.Label (null),
            decoration_layout = ";"
        };

        var main_accordion = new Widgets.Accordion () {
            has_header = false
        };
        main_accordion.add_child (new Widgets.SidebarRow (ViewType.HOME));

        var library_accordion = new Widgets.Accordion () {
            title = _("Library")
        };
        library_accordion.add_child (new Widgets.SidebarRow (ViewType.RECENTLY_ADDED));
        library_accordion.add_child (new Widgets.SidebarRow (ViewType.ARTISTS));
        library_accordion.add_child (new Widgets.SidebarRow (ViewType.ALBUMS));
        library_accordion.add_child (new Widgets.SidebarRow (ViewType.SONGS));        

        var playlist_accordion = new Widgets.Accordion () {
            title = _("Playlist")
        };
        playlist_accordion.add_child (new Widgets.SidebarRow (ViewType.PLAYLIST));
        
        var main_box = new Gtk.Box (VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12
        };
        main_box.append (main_accordion);
        main_box.append (library_accordion);
        main_box.append (playlist_accordion);

        var toolbar_view = new Adw.ToolbarView () {
            content = main_box
        };
        toolbar_view.add_top_bar (headerbar);

        child = toolbar_view;
    }
 }