/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.MediaControlButtons : Adw.Bin {
    private Gtk.Image icon_play;
    private Gtk.Image icon_pause;
    private Gtk.Image icon_stop;
    private Gtk.Image icon_previous;
    private Gtk.Image icon_next;

    private Gtk.Button play_button;
    private Gtk.Button next_button;
    private Gtk.Button previous_button;

    public int icon_size {
        set {
            icon_play.pixel_size = value;
            icon_pause.pixel_size = value;
            icon_stop.pixel_size = value;
            icon_previous.pixel_size = value - 24;
            icon_next.pixel_size = value - 24;
        }
    }

    public signal void toggle_playing ();

    construct {
        icon_play = new Gtk.Image.from_icon_name ("media-playback-start-symbolic");
        icon_pause = new Gtk.Image.from_icon_name ("media-playback-pause-symbolic");
        icon_stop = new Gtk.Image.from_icon_name ("media-playback-stop-symbolic");
        icon_previous = new Gtk.Image.from_icon_name ("media-skip-backward-symbolic");
        icon_next = new Gtk.Image.from_icon_name ("media-skip-forward-symbolic");

        previous_button = new Gtk.Button () {
            child = icon_previous,
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
            child = icon_next,
            focusable = false,
            tooltip_text = _ ("Next"),
            valign = Gtk.Align.CENTER,

        };
        next_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);

        var control_box = new Gtk.Box (HORIZONTAL, 0);
        control_box.append (previous_button);
        control_box.append (play_button);
        control_box.append (next_button);

        child = control_box;

        play_button.clicked.connect (() => {
            Services.Player.instance ().toggle_playing ();
        });

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
    }
 }