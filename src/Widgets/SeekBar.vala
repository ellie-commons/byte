/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.SeekBar : Adw.Bin {
    private double _playback_duration;
    private double _playback_progress;

    /*
     * The time of the full duration of the playback.
     */

    public double playback_duration {
        get {
            return _playback_duration;
        }
        set {
            double duration = value;
            if (duration < 0.0) {
                duration = 0.0;
            }

            _playback_duration = duration;
            
            duration_label.label = "<span font-features='tnum'>%s</span>".printf (
                Granite.DateTime.seconds_to_time ((int) duration)
            );
        }
    }

    /*
     * The progression of the playback as a decimal from 0.0 to 1.0.
     */

    public double playback_progress {
        get {
            return _playback_progress;
        }
        set {
            double progress = value;
            if (progress < 0.0) {
                progress = 0.0;
            } else if (progress > 1.0) {
                progress = 1.0;
            }

            _playback_progress = progress;
            scale.set_value (progress);

            progression_label.label = "<span font-features='tnum'>%s</span>".printf (
                Granite.DateTime.seconds_to_time ((int) (progress * playback_duration))
            );
        }
    }

    public bool is_grabbing { get; private set; default = false; }
    public bool is_hovering { get; private set; default = false; }

    public Gtk.Label progression_label { get; construct set; }
    public Gtk.Label duration_label { get; construct set; }
    public Gtk.Scale scale { get; construct set; }

    construct {
        progression_label = new Gtk.Label ("--:--") {
            use_markup = true
        };
        progression_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        duration_label = new Gtk.Label ("--:--") {
            use_markup = true
        };
        duration_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1, 0.1) {
            hexpand = true,
            draw_value = false
        };
        scale.add_css_class ("seekbar");

        var box = new Gtk.Box (HORIZONTAL, 6);
        box.append (progression_label);
        box.append (scale);
        box.append (duration_label);

        child = box;
        playback_progress = 0.0;

        var gesture_click = new Gtk.GestureClick ();
        scale.add_controller (gesture_click);
        
        gesture_click.pressed.connect ((n_press, x, y) => {
            is_grabbing = true;
        });

        gesture_click.released.connect ((n_press, x, y) => {
            is_grabbing = false;
            playback_progress = scale.get_value ();
        });

        var motion_gesture = new Gtk.EventControllerMotion ();
        scale.add_controller (motion_gesture);

        motion_gesture.enter.connect ((x, y) => {
            is_hovering = true;
        });

        motion_gesture.leave.connect (() => {
            is_hovering = false;
        });

        motion_gesture.motion.connect ((x, y) => {
            playback_progress = scale.get_value ();
        });
    }
 }