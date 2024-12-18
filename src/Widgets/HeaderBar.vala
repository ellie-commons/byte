/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.HeaderBar : Adw.Bin {
    construct {
        var headerbar = new Adw.HeaderBar () {
            decoration_layout = "close:menu"
        };
        headerbar.add_css_class ("primary-headerbar");

        var sidebar_button = new Gtk.Button.from_icon_name ("view-dual-symbolic");
        headerbar.pack_end (sidebar_button);

        child = headerbar;

        sidebar_button.clicked.connect (() => {
            Services.EventBus.instance ().show_sidebar ();
        });
    }
 }