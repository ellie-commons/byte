/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.SidebarRow : Gtk.ListBoxRow {
    public ViewType view_type { get; construct; }

    public SidebarRow (ViewType view_type) {
        Object (
            view_type: view_type
        );
    }

    construct {        
        add_css_class ("sidebar-row");
        remove_css_class ("activatable");

        var box = new Gtk.Box (HORIZONTAL, 6) {
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6,
            margin_end = 6
        };
        box.append (new Gtk.Image.from_icon_name (view_type.get_icon ()));
        box.append (new Gtk.Label (view_type.get_title ()));
        
        child = box;

        var select_gesture = new Gtk.GestureClick ();
        add_controller (select_gesture);
        select_gesture.released.connect (() => {
            Services.EventBus.instance ().select_view (view_type);
        });

        Services.EventBus.instance ().select_view.connect ((_view_type) => {
            if (view_type == _view_type) {
                add_css_class ("selected");
            } else {
                remove_css_class ("selected");
            }
        });
    }
 }