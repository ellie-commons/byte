/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.TrackRow : Gtk.ListBoxRow {
    public Objects.Track track { get; construct; }

    private Widgets.MediaCover media_cover;
    private Gtk.Label title_label;
    private Gtk.Label artist_label;

    public TrackRow (Objects.Track track) {
        Object (
            track: track
        );
    }

    construct {
        media_cover = new Widgets.MediaCover (32);
        media_cover.set_track (track);

        title_label = new Gtk.Label (track.title) {
            ellipsize = END,
            single_line_mode = true,
            halign = START,
            valign = END
        };
        title_label.get_style_context ().add_class ("font-bold");

        artist_label = new Gtk.Label (track.album.artist.name) {
            halign = START,
            valign = START,
            single_line_mode = true,
            ellipsize = END,
        };
        artist_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        artist_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var main_grid = new Gtk.Grid () {
            margin_top = 3,
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 3,
            column_spacing = 6
        };
        main_grid.attach (media_cover, 0, 0, 1, 2);
        main_grid.attach (title_label, 1, 0, 1, 1);
        main_grid.attach (artist_label, 1, 1, 1, 1);
        //  main_grid.attach (right_grid, 2, 0, 2, 2);

        child = main_grid;
    }
 }