/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.MediaControl : Adw.Bin {
    private Widgets.MediaCover media_cover;
    private Gtk.Label title_label;
    private Gtk.Label artist_label;

    private Gtk.Button shuffle_button;
    private Gtk.Button repeat_button;

    private Gtk.Image icon_shuffle_on;
    private Gtk.Image icon_shuffle_off;

    private Gtk.Image icon_repeat_one;
    private Gtk.Image icon_repeat_all;
    private Gtk.Image icon_repeat_off;

    private Gtk.Stack stack;
    private Gtk.Revealer stack_revealer;
    private Gtk.Revealer main_control_revealer;
    private Gtk.Box card;

    public signal void expanded ();

    bool _expand = false;
    public bool expand {
        get {
            return _expand;
        }

        set {
            _expand = value;
            stack_revealer.reveal_child = !value;
            main_control_revealer.reveal_child = value;

            if (_expand) {
                card.add_css_class ("active");
            } else {
                card.remove_css_class ("active");
            }
            
            expanded ();
        }
    }
    
    construct {
        media_cover = new Widgets.MediaCover () {
            size = 32
        };

        title_label = new Gtk.Label (null) {
            ellipsize = END,
            single_line_mode = true,
            halign = START,
            valign = END
        };
        title_label.get_style_context ().add_class ("font-bold");

        artist_label = new Gtk.Label (null) {
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

        var main_control_content = new Gtk.Box (HORIZONTAL, 6) {
            hexpand = true
        };

        main_control_content.append (current_track_grid);
        main_control_content.append (new Widgets.MediaControlButtons () {
            hexpand = true,
            halign = END,
            margin_end = 6
        });

        var sync_image = new Gtk.Image.from_icon_name ("emblem-synchronizing-symbolic") {
            pixel_size = 24,
            valign = CENTER,
            halign = CENTER
        };

        var sync_label = new Gtk.Label (_("Syncing Library…")) {
            valign = END,
            halign = START
        };
        sync_label.add_css_class ("small-label");
        sync_label.add_css_class ("font-bold");

        var sync_progressbar = new Gtk.ProgressBar () {
            valign = START,
            hexpand = true
        };

        var sync_content = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            row_spacing = 3,
            column_spacing = 6,
            margin_start = 6,
            margin_end = 6
        };
        sync_content.attach (sync_image, 0, 0, 1, 2);
        sync_content.attach (sync_label, 1, 0, 1, 1);
        sync_content.attach (sync_progressbar, 1, 1, 1, 1);
        
        stack = new Gtk.Stack () {
            transition_type = SLIDE_DOWN,
            hexpand = true,
            margin_top = 6,
            margin_bottom = 6
        };

        stack.add_child (main_control_content);
        stack.add_child (sync_content);

        stack_revealer = new Gtk.Revealer () {
            child = stack,
            reveal_child = true
        };

        var main_media_cover = new Widgets.MediaCover () {
            size = 128
        };

        var main_title_label = new Gtk.Label (null) {
            ellipsize = END,
            single_line_mode = true,
            halign = CENTER,
            hexpand = true,
            margin_top = 12
        };
        main_title_label.get_style_context ().add_class ("font-bold");

        var main_artist_label = new Gtk.Label (null) {
            ellipsize = END,
            single_line_mode = true,
            halign = CENTER,
            hexpand = true,
            margin_top = 3
        };
        main_artist_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        main_artist_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var timeline = new Widgets.SeekBar () {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12
        };

        icon_shuffle_on = new Gtk.Image.from_icon_name ("media-playlist-shuffle-symbolic");
        icon_shuffle_off = new Gtk.Image.from_icon_name ("media-playlist-no-shuffle-symbolic");

        shuffle_button = new Gtk.Button () {
            focusable = false,
            valign = CENTER,
            child = icon_shuffle_off
        };

        shuffle_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);

        var media_control_buttons = new Widgets.MediaControlButtons () {
            icon_size = 48
        };

        icon_repeat_one = new Gtk.Image.from_icon_name ("media-playlist-repeat-one-symbolic");
        icon_repeat_all = new Gtk.Image.from_icon_name ("media-playlist-repeat-symbolic");
        icon_repeat_off = new Gtk.Image.from_icon_name ("media-playlist-no-repeat-symbolic");

        repeat_button = new Gtk.Button () {
            focusable = false,
            valign = CENTER,
            child = icon_repeat_off
        };

        repeat_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);

        var media_control_box = new Gtk.Box (HORIZONTAL, 24) {
            hexpand = true,
            halign = CENTER,
            margin_top = 12,
        };

        media_control_box.append (shuffle_button);
        media_control_box.append (media_control_buttons);
        media_control_box.append (repeat_button);

        var main_control_box = new Gtk.Box (VERTICAL, 0) {
            margin_top = 24,
            height_request = 375
        };
        main_control_box.append (main_media_cover);
        main_control_box.append (timeline);
        main_control_box.append (main_title_label);
        main_control_box.append (main_artist_label);
        main_control_box.append (media_control_box);

        main_control_revealer = new Gtk.Revealer () {
            child = new Gtk.WindowHandle () {
                child = main_control_box
            },
            transition_type = SLIDE_UP
        };

        card = new Gtk.Box (VERTICAL, 0) {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };
        card.add_css_class (Granite.STYLE_CLASS_CARD);
        card.add_css_class (Granite.STYLE_CLASS_ROUNDED);
        card.add_css_class ("expand");

        card.append (stack_revealer);
        card.append (main_control_revealer);

        child = card;
        check_shuffle_button ();
        check_repeat_button ();
        
        Services.Player.instance ().current_track_changed.connect ((track) => {
            media_cover.set_track (track);
            main_media_cover.set_track (track);

            title_label.label = track.title;
            main_title_label.label = track.title;

            artist_label.label = track.album.artist.name;
            main_artist_label.label = track.album.artist.name;
        });

        Services.Scanner.instance ().sync_started.connect (() => {
            stack.visible_child = sync_content;
        });

        Services.Scanner.instance ().sync_progress.connect ((fraction) => {
            sync_progressbar.fraction = fraction;
        });

        Services.Scanner.instance ().sync_finished.connect (() => {
            stack.visible_child = main_control_content;
        });

        var expand_gesture = new Gtk.GestureClick ();
        main_control_content.add_controller (expand_gesture);
        expand_gesture.released.connect ((n_press, x, y) => {
            expand = true;
        });

        Services.Player.instance ().current_progress_changed.connect ((progress) => {
            timeline.playback_progress = progress;
            if (timeline.playback_duration == 0) {
                timeline.playback_duration = Services.Player.instance ().duration / Gst.SECOND;
            }
        });

        Services.Player.instance ().current_duration_changed.connect ((duration) => {
            timeline.playback_duration = duration / Gst.SECOND;
        });

        timeline.scale.change_value.connect ((scroll, new_value) => {
            Services.Player.instance ().seek_to_progress (new_value);
            return true;
        });

        shuffle_button.clicked.connect (() => {
            Services.Settings.instance ().settings.set_boolean ("shuffle-mode", !Services.Settings.instance ().settings.get_boolean ("shuffle-mode"));
            Services.Player.instance ().shuffle_changed (Services.Settings.instance ().settings.get_boolean ("shuffle-mode"));
        });

        repeat_button.clicked.connect (() => {
            var enum = Services.Settings.instance ().settings.get_enum ("repeat-mode");

            if (enum == 1) {
                Services.Settings.instance ().settings.set_enum ("repeat-mode", 2);
            } else if (enum == 2) {
                Services.Settings.instance ().settings.set_enum ("repeat-mode", 0);
            } else {
                Services.Settings.instance ().settings.set_enum ("repeat-mode", 1);
            }
        });

        Services.Settings.instance ().settings.changed["shuffle-mode"].connect (check_shuffle_button);
        Services.Settings.instance ().settings.changed["repeat-mode"].connect (check_repeat_button);
    }

    private void check_shuffle_button () {
        if (Services.Settings.instance ().settings.get_boolean ("shuffle-mode")) {
            shuffle_button.child = icon_shuffle_on;
            shuffle_button.tooltip_text = _ ("Shuffle On");
        } else {
            shuffle_button.child = icon_shuffle_off;
            shuffle_button.tooltip_text = _ ("Shuffle Off");
        }
    }

    private void check_repeat_button () {
        var repeat_mode = Services.Settings.instance ().settings.get_enum ("repeat-mode");

        if (repeat_mode == 0) {
            repeat_button.child = icon_repeat_off;
            repeat_button.tooltip_text = _ ("Repeat Off");
        } else if (repeat_mode == 1) {
            repeat_button.child = icon_repeat_all;
            repeat_button.tooltip_text = _ ("Repeat All");
        } else {
            repeat_button.child = icon_repeat_one;
            repeat_button.tooltip_text = _ ("Repeat One");
        }
    }
 }