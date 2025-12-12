public class Widgets.MediaControl : Gtk.Revealer {
    private Granite.SeekBar timeline;
    private Gtk.Label title_label;
    private Gtk.Label subtitle_label;

    private Gtk.Image icon_favorite;
    private Gtk.Image icon_no_favorite;

    private Gtk.ToggleButton history_button;
    private Gtk.ListBox radio_track_listbox;

    Gtk.Menu playlists;
    private Gtk.Menu menu = null;
    private Gtk.Popover popover = null;

    public MediaControl () {

    }

    construct {
        icon_favorite = new Gtk.Image.from_icon_name ("byte-favorite-symbolic", Gtk.IconSize.MENU);
        icon_no_favorite = new Gtk.Image.from_icon_name ("byte-no-favorite-symbolic", Gtk.IconSize.MENU);

        timeline = new Granite.SeekBar (0);
        timeline.margin_start = 6;
        timeline.margin_top = 9;
        timeline.margin_end = 6;
        timeline.get_style_context ().remove_class ("seek-bar");
        timeline.get_style_context ().add_class ("byte-seekbar");

        var timeline_revealer = new Gtk.Revealer ();
        timeline_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        timeline_revealer.add (timeline);
        timeline_revealer.reveal_child = false;

        title_label = new Gtk.Label (null);
        title_label.get_style_context ().add_class ("font-bold");
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.halign = Gtk.Align.CENTER;
        title_label.selectable = true;

        subtitle_label = new Gtk.Label (null);
        subtitle_label.halign = Gtk.Align.CENTER;
        subtitle_label.ellipsize = Pango.EllipsizeMode.END;
        subtitle_label.selectable = true;

        var options_button = new Gtk.Button.from_icon_name ("view-more-horizontal-symbolic", Gtk.IconSize.MENU);
        options_button.valign = Gtk.Align.CENTER;
        options_button.can_focus = false;
        options_button.tooltip_text = _("Options");
        options_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        options_button.get_style_context ().add_class ("options-button");
        options_button.get_style_context ().add_class ("button-color");
        options_button.get_style_context ().remove_class ("button");

        history_button = new Gtk.ToggleButton ();
        history_button.add (new Gtk.Image.from_icon_name ("radio-track-played-recent-symbolic", Gtk.IconSize.MENU));
        history_button.valign = Gtk.Align.CENTER;
        history_button.can_focus = false;
        history_button.tooltip_text = _("Recently Played");
        history_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        history_button.get_style_context ().add_class ("options-button");
        history_button.get_style_context ().add_class ("button-color");
        history_button.get_style_context ().remove_class ("button");
        
        var button_stack = new Gtk.Stack ();
        button_stack.width_request = 40;
        button_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        button_stack.add_named (options_button, "options_button");
        button_stack.add_named (history_button, "history_button");

        var button_revealer = new Gtk.Revealer ();
        button_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        button_revealer.add (button_stack);
        button_revealer.reveal_child = true;

        var metainfo_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        metainfo_box.margin_start = 6;
        metainfo_box.margin_end = 6;
        metainfo_box.valign = Gtk.Align.CENTER;
        metainfo_box.add (title_label);
        metainfo_box.add (subtitle_label);

        var image_cover = new Widgets.Cover ();

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_box.margin = 3;
        header_box.margin_start = 4;
        header_box.margin_end = 3;
        header_box.pack_start (image_cover, false, false, 0);
        header_box.set_center_widget (metainfo_box);
        header_box.pack_end (button_revealer, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.pack_start (timeline_revealer, false, false, 0);
        main_box.pack_start (header_box, false, false, 0);

        add (main_box);

        Byte.player.current_progress_changed.connect ((progress) => {
            timeline.playback_progress = progress;
            if (timeline.playback_duration == 0) {
                timeline.playback_duration = Byte.player.duration / Gst.SECOND;
            }
            // Save progress only every two seconds to reduce disk writes
            int int_progress = (int)(progress * 100);
            if (progress >= 0.0 && progress <= 0.99 && int_progress % 2 == 1) {
                Byte.settings.set_double ("track-progression", progress);
            }
        });

        Byte.player.current_duration_changed.connect ((duration) => {
            timeline.playback_duration = duration / Gst.SECOND;
        });

        Byte.player.current_track_changed.connect ((track) => {
            title_label.label = track.title;
            subtitle_label.label = "%s — %s".printf (track.artist_name, track.album_title);

            string cover_path = GLib.Path.build_filename (Byte.utils.COVER_FOLDER, ("track-%i.jpg").printf (track.id));
            image_cover.set_from_file (cover_path, 32, "track");
        });

        Byte.player.current_radio_changed.connect ((radio) => {
            title_label.label = radio.name;
            reveal_child = true;
        });

        Byte.player.current_radio_title_changed.connect ((title) => {
            if (Byte.player.mode == "radio") {
                subtitle_label.label = title;
            }
        });

        Byte.player.state_changed.connect ((state) => {
            if (state == Gst.State.PLAYING) {
                if (Byte.player.current_track != null) {
                    reveal_child = true;
                }
            } else if (state == Gst.State.NULL) {
                reveal_child = false;
            }
        });

        Byte.player.mode_changed.connect ((mode) => {
            if (mode == "radio") {
                timeline_revealer.reveal_child = false;
                button_stack.visible_child_name = "history_button";
            } else {
                timeline_revealer.reveal_child = true;
                if (Byte.scan_service.is_sync == false) {
                    button_stack.visible_child_name = "options_button";
                }
            }
        });

        Byte.lastfm_service.radio_cover_track_found.connect ((track_url) => {
            print ("URL: %s\n".printf (track_url));
            image_cover.set_from_url_async (track_url, 32, true, "track");
        });

        Byte.database.updated_track_cover.connect ((track_id) => {
            Idle.add (() => {
                if (Byte.player.current_track != null && track_id == Byte.player.current_track.id) {
                    try {
                        image_cover.pixbuf = new Gdk.Pixbuf.from_file_at_size (
                            GLib.Path.build_filename (Byte.utils.COVER_FOLDER, ("track-%i.jpg").printf (track_id)),
                            32,
                            32);
                    } catch (Error e) {
                        stderr.printf ("Error setting default avatar icon: %s ", e.message);
                    }
                }

                return false;
            });
        });

        timeline.scale.change_value.connect ((scroll, new_value) => {
            Byte.player.seek_to_progress (new_value);
            return true;
        });

        Byte.scan_service.sync_started.connect (() => {
            button_revealer.reveal_child = false;
        });

        Byte.scan_service.sync_finished.connect (() => {
            button_revealer.reveal_child = true;
        });

        options_button.clicked.connect (() => {
            if (Byte.player.current_track != null) {
                activate_menu (Byte.player.current_track);
            }
        });

        history_button.toggled.connect (() => {
            if (history_button.active) {
                activate_popover ();
            }
        });
    }

    private void activate_menu (Objects.Track track) {
        build_context_menu (track);

        foreach (var child in playlists.get_children ()) {
            child.destroy ();
        }

        if (Byte.scan_service.is_sync == false) {
            var all_items = Byte.database.get_all_playlists ();

            Widgets.MenuItem item;
            item = new Widgets.MenuItem (_("Create New Playlist"), "zoom-in-symbolic", _("Create New Playlist"));
            item.get_style_context ().add_class ("track-options");
            item.get_style_context ().add_class ("css-item");
            item.activate.connect (() => {
                var new_playlist = Byte.database.create_new_playlist ();
                Byte.database.insert_track_into_playlist (new_playlist, track);
            });
            playlists.add (item);

            foreach (var playlist in all_items) {
                item = new Widgets.MenuItem (playlist.title, "playlist-symbolic", playlist.title);
                item.get_style_context ().add_class ("track-options");
                item.get_style_context ().add_class ("css-item");
                item.activate.connect (() => {
                    Byte.database.insert_track_into_playlist (playlist, track);
                });
                playlists.add (item);
            }
            playlists.show_all ();
        }

        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Track track) {
        menu = new Gtk.Menu ();
        menu.get_style_context ().add_class ("view");

        var primary_label = new Gtk.Label (track.title);
        primary_label.get_style_context ().add_class ("font-bold");
        primary_label.ellipsize = Pango.EllipsizeMode.END;
        primary_label.max_width_chars = 25;
        primary_label.halign = Gtk.Align.START;

        var secondary_label = new Gtk.Label ("%s - %s".printf (track.artist_name, track.album_title));
        secondary_label.halign = Gtk.Align.START;
        secondary_label.max_width_chars = 25;
        secondary_label.ellipsize = Pango.EllipsizeMode.END;

        var cover_path = GLib.Path.build_filename (Byte.utils.COVER_FOLDER, ("track-%i.jpg").printf (track.id));
        var image_cover = new Gtk.Image ();
        image_cover.halign = Gtk.Align.START;
        image_cover.valign = Gtk.Align.START;
        try {
            image_cover.pixbuf = new Gdk.Pixbuf.from_file_at_size (cover_path, 38, 38);
        } catch (Error e) {
            image_cover.pixbuf = new Gdk.Pixbuf.from_resource_at_scale ("/com/github/alainm23/byte/track-default-cover.svg", 38, 38, true);
        }

        var track_grid = new Gtk.Grid ();
        track_grid.width_request = 185;
        track_grid.hexpand = false;
        track_grid.halign = Gtk.Align.START;
        track_grid.valign = Gtk.Align.CENTER;
        track_grid.column_spacing = 6;
        track_grid.attach (image_cover, 0, 0, 1, 2);
        track_grid.attach (primary_label, 1, 0, 1, 1);
        track_grid.attach (secondary_label, 1, 1, 1, 1);

        var track_menu = new Gtk.MenuItem ();
        track_menu.get_style_context ().add_class ("track-options");
        track_menu.get_style_context ().add_class ("css-item");
        track_menu.right_justified = true;
        track_menu.add (track_grid);

        var play_menu = new Widgets.MenuItem (_("Play"), "media-playback-start-symbolic", _("Play"));
        var play_next_menu = new Widgets.MenuItem (_("Play Next"), "byte-play-next-symbolic", _("Play Next"));
        var play_last_menu = new Widgets.MenuItem (_("Play Later"), "byte-play-later-symbolic", _("Play Later"));

        var view_menu = new Widgets.MenuItem (_("Go to"), "go-jump-symbolic", _("View"));
        var views_menu = new Gtk.Menu ();
        views_menu.get_style_context ().add_class ("view");
        view_menu.set_submenu (views_menu);

        var artist_menu = new Widgets.MenuItem (track.artist_name, "avatar-default-symbolic", _("Artist"));
        var album_menu = new Widgets.MenuItem (track.album_title, "media-optical-symbolic", _("Album"));
        var playlist_menu = new Widgets.MenuItem (track.playlist_title, "playlist-symbolic", _("Playlist"));

        views_menu.add (artist_menu);
        views_menu.add (album_menu);

        var add_playlist_menu = new Widgets.MenuItem (_("Add to Playlist"), "zoom-in-symbolic", _("Add to Playlist"));
        playlists = new Gtk.Menu ();
        playlists.get_style_context ().add_class ("view");
        add_playlist_menu.set_submenu (playlists);

        var edit_menu = new Widgets.MenuItem (_("Edit Song Info…"), "edit-symbolic", _("Edit Song Info…"));

        var favorite_menu = new Widgets.MenuItem (_("Love"), "byte-favorite-symbolic", _("Love"));
        var no_favorite_menu = new Widgets.MenuItem (_("Dislike"), "byte-no-favorite-symbolic", _("Dislike"));

        var remove_db_menu = new Widgets.MenuItem (_("Delete from library"), "user-trash-symbolic", _("Delete from library"));
        var remove_file_menu = new Widgets.MenuItem (_("Delete from file"), "user-trash-symbolic", _("Delete from file"));
        var remove_playlist_menu = new Widgets.MenuItem (_("Remove from playlist"), "zoom-out-symbolic", _("Remove from playlist"));

        menu.add (track_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (play_menu);
        menu.add (play_next_menu);
        menu.add (play_last_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (view_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (add_playlist_menu);
        //menu.add (edit_menu);
        menu.add (favorite_menu);
        menu.add (no_favorite_menu);
        menu.add (new Gtk.SeparatorMenuItem ());

        if (track.playlist_id != 0) {
            menu.add (remove_playlist_menu);
            views_menu.add (playlist_menu);
        }

        menu.add (remove_db_menu);

        menu.show_all ();
        views_menu.show_all ();

        track_menu.activate.connect (() => {
            this.activate ();
        });

        play_menu.activate.connect (() => {
            this.activate ();
        });

        play_next_menu.activate.connect (() => {
            Byte.utils.set_next_track (track);
        });

        play_last_menu.activate.connect (() => {
            Byte.utils.set_last_track (track);
        });

        favorite_menu.activate.connect (() => {
            if (Byte.scan_service.is_sync == false) {
                Byte.database.set_track_favorite (track, 1);
            }
        });

        no_favorite_menu.activate.connect (() => {
            if (Byte.scan_service.is_sync == false) {
                Byte.database.set_track_favorite (track, 0);
            }
        });

        artist_menu.activate.connect (() => {
            var artist = Byte.database.get_artist_by_id (track.artist_id);

            if (!Byte.navCtrl.has_key ("artist-%i".printf (artist.id))) {
                var view = new Views.Artist (artist);
                Byte.navCtrl.add_named (view, "artist-%i".printf (artist.id));
            }
    
            Byte.navCtrl.push ("artist-%i".printf (artist.id));
        });

        album_menu.activate.connect (() => {
            var album = Byte.database.get_album_by_id (track.album_id);

            if (!Byte.navCtrl.has_key ("album-%i".printf (album.id))) {
                var album_view = new Views.Album (album);
                Byte.navCtrl.add_named (album_view, "album-%i".printf (album.id));
            }

            Byte.navCtrl.push ("album-%i".printf (album.id));
        });

        playlist_menu.activate.connect (() => {
            var playlist = Byte.database.get_playlist_by_id (track.playlist_id);

            if (!Byte.navCtrl.has_key ("playlist-%i".printf (playlist.id))) {
                var album_view = new Views.Playlist (playlist);
                Byte.navCtrl.add_named (album_view, "playlist-%i".printf (playlist.id));
            }

            Byte.navCtrl.push ("playlist-%i".printf (playlist.id));
        });

        edit_menu.activate.connect (() => {
            var editor_dialog = new Dialogs.TrackEditor (track);
            editor_dialog.destroy.connect (Gtk.main_quit);
            editor_dialog.show_all ();
        });

        remove_db_menu.activate.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete from library?"),
                _("Are you sure you want to delete <b>%s</b> from your library?").printf (track.title),
                "dialog-warning",
                Gtk.ButtonsType.CANCEL
            );

            var set_button = new Gtk.Button.with_label (_("Delete"));
            set_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (set_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                Byte.database.remove_from_library (track);
            }

            message_dialog.destroy ();
        });

        remove_file_menu.activate.connect (() => {

        });

        remove_playlist_menu.activate.connect (() => {
            if (Byte.database.remove_from_playlist (track)) {
                destroy ();
            }
        });
    }

    private void activate_popover () {
        if (popover == null) {
            build_history_popover ();
        }

        foreach (var child in radio_track_listbox.get_children ()) {
            child.destroy ();
        }

        foreach (var r in Byte.database.get_radio_track_history (Byte.player.current_radio.id)) {
            var row = new Widgets.RadioTrackRow (r.radio_id, r.title, r.date_added);

            radio_track_listbox.add (row);
            radio_track_listbox.show_all ();
        }

        popover.popup ();
    }

    private void build_history_popover () {
        popover = new Gtk.Popover (history_button);
        popover.position = Gtk.PositionType.BOTTOM;

        radio_track_listbox = new Gtk.ListBox ();
        radio_track_listbox.selection_mode = Gtk.SelectionMode.NONE;
        radio_track_listbox.expand = true;

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.expand = true;
        listbox_scrolled.add (radio_track_listbox);

        var header_label = new Granite.HeaderLabel (_("Radio tracks history"));
        header_label.halign = Gtk.Align.CENTER;

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 255;
        popover_grid.height_request = 250;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (header_label);
        popover_grid.add (listbox_scrolled);
        popover_grid.show_all ();

        popover.add (popover_grid);

        Byte.database.radio_track_added.connect ((radio_id, title, date_added) => {
            var row = new Widgets.RadioTrackRow (radio_id, title, date_added);

            radio_track_listbox.insert (row, 0);
            radio_track_listbox.show_all ();
        });

        popover.closed.connect (() => {
            history_button.active = false;
        });
    }
}

public class Widgets.RadioTrackRow : Gtk.ListBoxRow {
    public int radio_id { get; construct; }
    public string title { get; construct; }
    public string date_added { get; construct; }

    public GLib.DateTime _date;
    public GLib.DateTime date {
        get {
            _date = new GLib.DateTime.from_iso8601 (date_added, new GLib.TimeZone.local ());
            return _date;
        }
    }

    public RadioTrackRow (int radio_id, string title, string date_added) {
        Object (
            radio_id: radio_id,
            title: title,
            date_added: date_added
        );
    }

    construct {
        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("folder-music-symbolic");
        icon.pixel_size = 16;

        var title_label = new Gtk.Label (title);
        title_label.get_style_context ().add_class ("font-bold-600");
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.selectable = true;
        title_label.valign = Gtk.Align.CENTER;

        var date_label = new Gtk.Label (date.format (Granite.DateTime.get_default_time_format (true, false)));
        date_label.halign = Gtk.Align.START;
        date_label.valign = Gtk.Align.CENTER;
        
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.margin = 6;
        box.margin_top = 0;
        box.pack_start (icon, false, false, 0);
        box.pack_start (title_label, false, false, 0);
        //box.pack_end (date_label, false, false, 0);

        add (box);
    }
}