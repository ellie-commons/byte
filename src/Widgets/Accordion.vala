

/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Widgets.Accordion : Adw.Bin {
    private Gtk.Label title_label;
    private Gtk.Button header_button;
    private Gtk.ListBox listbox;

    public string title {
        set {
            title_label.label = value;
        }
    }

    public bool has_header {
        set {
            header_button.visible = value;
        }
    }

    construct {
        title_label = new Gtk.Label (null) {
            halign = Gtk.Align.START,
            ellipsize = Pango.EllipsizeMode.END
        };
        title_label.add_css_class ("title-4");

        var hide_image = new Gtk.Image.from_icon_name ("pan-end-symbolic") {
            hexpand = true,
            halign = END
        };
        hide_image.add_css_class ("primary-color");
        hide_image.add_css_class ("hidden-button");
        hide_image.add_css_class ("opened");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 6,
            margin_end = 6
        };

        header_box.append (title_label);
        header_box.append (hide_image);

        header_button = new Gtk.Button () {
            child = header_box,
            focusable = false
        };
        header_button.add_css_class ("flat");
        header_button.add_css_class ("no-padding");

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        listbox.add_css_class ("library-sidebar");
        listbox.add_css_class ("background");

        var listbox_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = listbox,
            reveal_child = true
        };

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6,
            margin_start = 3,
            margin_bottom = 3
        };

        var separator_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = separator
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            margin_top = 3
        };

        content_box.append (header_button);
        content_box.append (separator_revealer);
        content_box.append (listbox_revealer);

        child = content_box;

        header_button.clicked.connect (() => {
            listbox_revealer.reveal_child = !listbox_revealer.reveal_child;
            separator_revealer.reveal_child = !listbox_revealer.reveal_child;
            
            if (listbox_revealer.reveal_child) {
                hide_image.add_css_class ("opened");
            } else {
                hide_image.remove_css_class ("opened");
            }
        });
    }

    public void add_child (Gtk.Widget widget) {
        listbox.append (widget);
    }
}