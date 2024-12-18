/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public class Views.Welcome : Adw.Bin {
    public signal void selected (int active);

    construct {
        var placeholder = new Granite.Placeholder (_("Library is Empty")) {
            description = _("Add music to start jamming out")
        };

        var load_folder = placeholder.append_button (
            new ThemedIcon ("byte-folder-music"),
            _("Load Music"),
            _("Load from the user's music directory")
        );

        var custom_folder = placeholder.append_button (
            new ThemedIcon ("byte-folder-open"),
            _("Change Music Folder"),
            _("Load music from folder")
        );

        var toolbar_view = new Adw.ToolbarView () {
            content = placeholder
        };
        toolbar_view.add_top_bar (new Widgets.HeaderBar ());

        child = toolbar_view;

        load_folder.clicked.connect (() => {
            selected (0);
        });

        custom_folder.clicked.connect (() => {
            selected (1);
        });
    }
}