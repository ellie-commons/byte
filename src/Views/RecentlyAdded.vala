
/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Views.RecentlyAdded : Adw.Bin {
    construct {
        var content_box = new Gtk.Box (VERTICAL, 0) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
         };
   
         var toolbar_view = new Adw.ToolbarView () {
            content = content_box
         };
         toolbar_view.add_top_bar (new Widgets.HeaderBar ());
   
         child = toolbar_view;
    }
 }