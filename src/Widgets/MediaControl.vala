/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.MediaControl : Adw.Bin {
    private Widgets.MediaCover media_cover;
    private Gtk.Label title_label;
    private Gtk.Label artist_label;

    public Gtk.Image icon_play;
    public Gtk.Image icon_pause;
    public Gtk.Image icon_stop;

    public Gtk.Button play_button;
    private Gtk.Button next_button;
    private Gtk.Button previous_button;
    
    construct {
        media_cover = new Widgets.MediaCover (32);

        title_label = new Gtk.Label ("Title") {
            ellipsize = END,
            single_line_mode = true,
            halign = START,
            valign = END
        };
        title_label.get_style_context ().add_class ("font-bold");

        artist_label = new Gtk.Label ("Artist") {
            halign = START,
            valign = START,
            single_line_mode = true,
            ellipsize = END,
        };
        artist_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        artist_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var current_track_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin_start = 6,
            valign = CENTER
        };
        current_track_grid.attach (media_cover, 0, 0, 1, 2);
        current_track_grid.attach (title_label, 1, 0, 1, 1);
        current_track_grid.attach (artist_label, 1, 1, 1, 1);

        icon_play = new Gtk.Image.from_icon_name ("media-playback-start-symbolic");
        icon_pause = new Gtk.Image.from_icon_name ("media-playback-pause-symbolic");
        icon_stop = new Gtk.Image.from_icon_name ("media-playback-stop-symbolic");

        previous_button = new Gtk.Button () {
            child = new Gtk.Image.from_icon_name ("media-skip-backward-symbolic"),
            focusable = false,
            tooltip_text = _ ("Previous"),
            valign = Gtk.Align.CENTER
        };
        previous_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);

        play_button = new Gtk.Button () {
            focusable = false,
            valign = Gtk.Align.CENTER,
            child = icon_play,
            tooltip_text = _ ("Play")
        };
        play_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);

        next_button = new Gtk.Button () {
            child = new Gtk.Image.from_icon_name ("media-skip-forward-symbolic"),
            focusable = false,
            tooltip_text = _ ("Next"),
            valign = Gtk.Align.CENTER,

        };
        next_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);

        var control_box = new Gtk.Box (HORIZONTAL, 0) {
            hexpand = true,
            halign = END,
            margin_end = 6,
            valign = CENTER
        };

        control_box.append (previous_button);
        control_box.append (play_button);
        control_box.append (next_button);

        var main_content = new Gtk.Box (HORIZONTAL, 6) {
            hexpand = true
        };

        main_content.append (current_track_grid);
        main_content.append (control_box);

        var card = new Adw.Bin () {
            child = main_content,
            height_request = 42,
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };
        card.add_css_class (Granite.STYLE_CLASS_CARD);
        card.add_css_class (Granite.STYLE_CLASS_ROUNDED);

        child = card;

        play_button.clicked.connect (() => {
            Services.Player.instance ().toggle_playing ();
        });

        Services.Player.instance ().toggle_playing.connect (toggle_playing);

        Services.Player.instance ().state_changed.connect ((state) => {
            if (state == Gst.State.PLAYING) {
                play_button.child = icon_pause;
            } else {
                play_button.child = icon_play;
            }
        });

        previous_button.clicked.connect (() => {
            Services.Player.instance ().prev ();
        });

        next_button.clicked.connect (() => {
            Services.Player.instance ().next ();
        });

        Services.Player.instance ().current_track_changed.connect ((track) => {
            media_cover.set_track (track);
            title_label.label = track.title;
            artist_label.label = track.album.artist.name;
        });
    }

    private void toggle_playing () {
        if (play_button.child == icon_play) {
            play_button.child = icon_pause;
            Services.Player.instance ().state_changed (Gst.State.PLAYING);
        } else if (play_button.child == icon_pause) {
            play_button.child = icon_play;
            Services.Player.instance ().state_changed (Gst.State.PAUSED);
        } else {
            play_button.child = icon_play;
            Services.Player.instance ().state_changed (Gst.State.READY);
        }
    }
 }