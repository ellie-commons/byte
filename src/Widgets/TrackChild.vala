/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.TrackChild : Gtk.FlowBoxChild {
    public Objects.Track track { get; construct; }

    private Gtk.Revealer main_revealer;

    public TrackChild (Objects.Track track) {
        Object (
            track: track
        );
    }

    construct {
        var track_widget = new Widgets.TrackWidget (track);
        
        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = track_widget
        };

        child = main_revealer;

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.FlowBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
 }