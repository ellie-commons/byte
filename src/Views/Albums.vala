
/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Views.Albums : Adw.Bin {
    private Gtk.Label title_label;
    private Gtk.Label tracks_label;
    private Gtk.ListBox listbox;

    private Gee.ArrayList<Objects.Track> tracks;

    construct {
        title_label = new Gtk.Label (_("Albums")) {
            margin_start = 9,
            halign = START
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H1_LABEL);

        tracks_label = new Gtk.Label ("%d Songs".printf (Services.Library.instance ().tracks.size)) {
            margin_start = 12,
            halign = START
        };
        tracks_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        tracks_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var play_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = CENTER
        };
        play_box.append (new Gtk.Image.from_icon_name ("media-playback-start-symbolic") {
            pixel_size = 12
        });
        play_box.append (new Gtk.Label (_("Play")));

        var shuffle_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = CENTER
        };
        shuffle_box.append (new Gtk.Image.from_icon_name ("media-playlist-shuffle-symbolic") {
            pixel_size = 12
        });
        shuffle_box.append (new Gtk.Label (_("Shuffle")));

        var play_button = new Gtk.Button () {
            child = play_box,
            focusable = false
        };

        play_button.add_css_class ("primary-color");
        play_button.add_css_class ("border-radius-6");

        var shuffle_button = new Gtk.Button () {
            child = shuffle_box,
            focusable = false
        };

        shuffle_button.add_css_class ("primary-color");
        shuffle_button.add_css_class ("border-radius-6");

        var play_suffle_box = new Gtk.Box (HORIZONTAL, 6) {
            hexpand = true,
            homogeneous = true,
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9,
            margin_top = 6
        };
        play_suffle_box.append (play_button);
        play_suffle_box.append (shuffle_button);

        listbox = new Gtk.ListBox () {
            margin_bottom = 50,
            margin_start = 6,
            margin_end = 6
        };
        listbox.add_css_class ("background");

        var content_box = new Gtk.Box (VERTICAL, 0);
        content_box.append (title_label);
        content_box.append (tracks_label);
        content_box.append (play_suffle_box);
        content_box.append (listbox);

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = content_box
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = listbox_scrolled
        };
        toolbar_view.add_top_bar (new Widgets.HeaderBar ());

        child = toolbar_view;
        load_tracks ();
        add_tracks ();

        listbox.row_activated.connect ((_row) => {
            var row = (Widgets.TrackRow) _row;
            Services.Player.instance ().set_tracks (
                tracks,
                Byte.settings.get_boolean ("shuffle-mode"),
                row.track
            );
        });

        play_button.clicked.connect (() => {
            Services.Player.instance ().set_tracks (
                tracks,
                false,
                null
            );
        });

        shuffle_button.clicked.connect (() => {
            Services.Player.instance ().set_tracks (
                tracks,
                true,
                null
            );
        });
    }

    private void load_tracks () {
        if (tracks == null) {
            tracks = new Gee.ArrayList<Objects.Track> ();
        }

        int index = 0;
        foreach (Objects.Track track in Services.Library.instance ().tracks) {
            track.track_order = index;
            tracks.add (track);
            index = index + 1;
        }
    }

    private void add_tracks () {
        foreach (Objects.Track track in tracks) {
            listbox.append (new Widgets.TrackRow (track));
        }
    }
 }