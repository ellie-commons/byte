/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Services.Player : GLib.Object {
    public signal void state_changed (Gst.State state);
    public signal void mode_changed (string mode);

    public signal void current_progress_changed (double percent);
    public signal void current_duration_changed (int64 duration);

    public signal void current_track_changed (Objects.Track? track);

    uint progress_timer = 0;

    public Objects.Track? current_track { get; set; default = null; }
    public string? mode { get; set; }
    public Gst.State? player_state { get; set; }
    public Gee.ArrayList<Objects.Track?> queue_playlist { set; get; }

    Gst.Format fmt = Gst.Format.TIME;
    dynamic Gst.Element playbin;
    Gst.Bus bus;

    public unowned int64 duration {
        get {
            int64 d = 0;
            playbin.query_duration (fmt, out d);
            return d;
        }
    }

    public unowned int64 position {
        get {
            int64 d = 0;
            playbin.query_position (fmt, out d);
            return d;
        }
    }

    public double target_progress { get; set; default = 0; }

    public bool can_play { get; set; default = true; }

    public bool can_go_next { get; set; default = true; }

    public bool can_go_previous { get; set; default = true; }

    static GLib.Once<Services.Player> _instance;
    public static unowned Services.Player instance () {
        return _instance.once (() => {
            return new Services.Player ();
        });
    }

    construct {
        playbin = Gst.ElementFactory.make ("playbin", "play");

        bus = playbin.get_bus ();
        bus.add_watch (0, bus_callback);
        bus.enable_sync_message_emission ();

        state_changed.connect ((state) => {
            player_state = state;
            stop_progress_signal ();

            if (state != Gst.State.NULL) {
                playbin.set_state (state);
            }
            
            switch (state) {
                case Gst.State.PLAYING:
                    start_progress_signal ();
                    break;
                case Gst.State.READY:
                    stop_progress_signal (true);
                    break;
                case Gst.State.PAUSED:
                    pause_progress_signal ();
                    break;
            }
        });

        current_track_changed.connect ((track) => {            
            if (track != null) {
                Services.Library.instance ().update_track_count (track);
            }
        });
    }

    public void set_track (Objects.Track? track) {
        if (track == null) {
            current_duration_changed (0);
        }

        if (load_track (track)) {
            current_track_changed (track);
            mode_changed ("track");
            mode = "track";

            play ();
        }
    }

    public bool load_track (Objects.Track? track, double progress = 0) {
        if (track == current_track || track == null) {
            return false;
        }

        current_track = track;
        
        var last_state = get_state ();
        stop ();

        playbin.uri = current_track.path;
        playbin.set_state (Gst.State.PLAYING);
        state_changed (Gst.State.PLAYING);
        player_state = Gst.State.PLAYING;

        while (duration == 0) {};

        if (last_state != Gst.State.PLAYING) {
            pause ();
        }

        current_duration_changed (duration);

        if (progress > 0) {
            seek_to_progress (progress);
            current_progress_changed (progress);
        }
        
        return true;
    }

    public Gst.State get_state () {
        Gst.State state = Gst.State.NULL;
        Gst.State pending;
        playbin.get_state (out state, out pending, (Gst.ClockTime) (Gst.SECOND));
        return state;
    }

    public void reset_playing () {
        if (current_track != null) {
            state_changed (Gst.State.READY);
            state_changed (Gst.State.NULL);
        }
    }

    public void toggle_playing () {
        var state = get_state ();
        if (state == Gst.State.PLAYING) {
            pause ();
        } else if (state == Gst.State.PAUSED || state == Gst.State.READY) {
            play ();
        }
    }

    public void play () {
        if (current_track != null) {
            state_changed (Gst.State.PLAYING);
            player_state = Gst.State.PLAYING;
        }
    }

    public void pause () {
        state_changed (Gst.State.PAUSED);
        player_state = Gst.State.PAUSED;
    }

    public void stop () {
        state_changed (Gst.State.READY);
        player_state = Gst.State.READY;
    }

    public void next () {
        if (current_track == null) {
            return;
        }

        Objects.Track? next_track = null;

        var repeat_mode = Services.Settings.instance ().settings.get_enum ("repeat-mode");
        if (repeat_mode == 2) {
            next_track = current_track;
            current_track = null;
        } else {
            next_track = get_next_track (current_track);
        }

        if (next_track != null) {
            set_track (next_track);
        } else {
            state_changed (Gst.State.NULL);
            player_state = Gst.State.NULL;
        }
    }

    public void prev () {        
        if (current_track == null) {
            return;
        }

        if (get_position_sec () < 1) {
            Objects.Track? prev_track = null;
            prev_track = get_prev_track (current_track);

            if (prev_track != null) {
                set_track (prev_track);
            }
        } else {
            stop ();
            play ();

            current_track_changed (current_track);
        }
    }

    public void seek_to_progress (double percent) {
        seek_to_position ((int64)(percent * duration));
    }

    public void seek_to_position (int64 position) {
        playbin.seek_simple (fmt, Gst.SeekFlags.FLUSH, position);
    }

    public void stop_progress_signal (bool reset_timer = false) {
        pause_progress_signal ();
        if (reset_timer) {
            current_progress_changed (0);
        }
    }

    public void start_progress_signal () {
        pause_progress_signal ();
        progress_timer = GLib.Timeout.add (250, () => {
            current_progress_changed (get_position_progress ());
            return true;
        });
    }

    public void pause_progress_signal () {
        if (progress_timer != 0) {
            Source.remove (progress_timer);
            progress_timer = 0;
        }
    }

    private unowned int64 get_position_sec () {
        int64 current = position;
        return current > 0 ? current / Gst.SECOND : -1;
    }
    
    public unowned double get_position_progress () {
        return (double) 1 / duration * position;
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
            case Gst.MessageType.ERROR:
                GLib.Error err;
                string debug;
                message.parse_error (out err, out debug);
                break;
            case Gst.MessageType.EOS:
                next ();
                break;
            default:
                break;
        }

        return true;
    }

    public void set_tracks (Gee.ArrayList<Objects.Track?> tracks, bool shuffle_mode, Objects.Track? track) {
        if (tracks.size <= 0) {
            return;
        }

        if (shuffle_mode) {
            queue_playlist = generate_shuffle (tracks);

            if (track != null) {
                int index = get_track_index_by_id (track.id, queue_playlist);
                queue_playlist.remove_at (index);
                queue_playlist.insert (0, track);
            }

            Services.Settings.instance ().settings.set_boolean ("shuffle-mode", true);
        } else {
            queue_playlist = sort_playlist (tracks);
            Services.Settings.instance ().settings.set_boolean ("shuffle-mode", false);
        }

        play_tracks (queue_playlist, track);
    }

    public void shuffle_changed (bool shuffle_mode) {
        if (queue_playlist == null) {
            return;
        }

        if (shuffle_mode) {
            queue_playlist = generate_shuffle (queue_playlist);

            if (current_track != null) {
                int index = get_track_index_by_id (current_track.id, queue_playlist);
                queue_playlist.remove_at (index);
                queue_playlist.insert (0, current_track);
            }
        } else {
            queue_playlist = sort_playlist (queue_playlist);
        }

        play_tracks (queue_playlist, current_track);
    }

    private Gee.ArrayList<Objects.Track?> sort_playlist (Gee.ArrayList<Objects.Track?> tracks) {
        for (int j = 0; j < tracks.size; j++) {
            for (int i = 0; i < tracks.size - 1; i++) {
                if (tracks[i].track_order > tracks[i + 1].track_order) {
                    var tmp_track = tracks[i + 1];
                    tracks[i + 1] = tracks[i];
                    tracks[i] = tmp_track;
                }
            }
        }

        return tracks;
    }

    public Gee.ArrayList<Objects.Track?> generate_shuffle (Gee.ArrayList<Objects.Track?> tracks) {
        for (int i = tracks.size - 1; i > 0; i--) {
            int random_index = GLib.Random.int_range (0, i);

            var tmp_track = tracks[random_index];
            tracks[random_index] = tracks[i];
            tracks[i] = tmp_track;
        }

        return tracks;
    }

    private void play_tracks (Gee.ArrayList<Objects.Track?> tracks, Objects.Track? track) {
        if (track == null) {
            set_track (tracks [0]);
        } else {
            set_track (track);
        }
    }

    public int get_track_index_by_id (string id, Gee.ArrayList<Objects.Track?> queue_playlist) {
        int index = 0;
        foreach (var item in queue_playlist) {
            if (item.id == id) {
                return index;
            }

            index++;
        }

        return index;
    }

    public Objects.Track? get_next_track (Objects.Track current_track) {
        int index = get_track_index_by_id (current_track.id, queue_playlist) + 1;
        Objects.Track? returned = null;
        var repeat_mode = Services.Settings.instance ().settings.get_enum ("repeat-mode");

        if (index >= queue_playlist.size) {
            if (repeat_mode == 0) {
                returned = null;
            } else if (repeat_mode == 1) {
                returned = queue_playlist [0];
            } else {
                returned = null;
            }
        } else {
            returned = queue_playlist [index];
        }

        return returned;
    }

    public Objects.Track get_prev_track (Objects.Track current_track) {
        int index = get_track_index_by_id (current_track.id, queue_playlist) - 1;

        if (index < 0) {
            index = 0;
        }

        return queue_playlist [index];
    }
 }