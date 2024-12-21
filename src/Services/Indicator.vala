/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public class Services.Indicator : GLib.Object {
    SoundIndicatorPlayer player;
    SoundIndicatorRoot root;

    public void initialize () {
        var mpris_id = Bus.own_name (
            BusType.SESSION,
            "org.mpris.MediaPlayer2.io.github.ellie_commons.byte",
            GLib.BusNameOwnerFlags.NONE,
            on_bus_acquired,
            null,
            null
        );

        if (mpris_id == 0) {
            warning ("Could not initialize MPRIS session.\n"); 
        }
    }

    private void on_bus_acquired (DBusConnection connection, string name) {
        try {
            connection.register_object ("/org/mpris/MediaPlayer2", new SoundIndicatorRoot ());
            connection.register_object ("/org/mpris/MediaPlayer2", new SoundIndicatorPlayer (connection));
        } catch(Error e) {
            warning ("could not create MPRIS player: %s\n", e.message);
        }
    }
}

[DBus(name = "org.mpris.MediaPlayer2")]
public class SoundIndicatorRoot : GLib.Object {
    Byte app;

    construct {
        app = Byte.instance;
    }

    public string DesktopEntry {
        owned get {
            return app.application_id;
        }
    }
}

[DBus(name = "org.mpris.MediaPlayer2.Player")]
public class SoundIndicatorPlayer : GLib.Object {
    [DBus (visible = false)]
    public unowned DBusConnection connection { get; construct; }
    
    public bool can_go_next { get; set; }
    public bool can_go_previous { get; set; }
    public bool can_play { get; set; }

    public string playback_status {
        get {
            var state = Services.Player.instance ().get_state ();
            if (state == Gst.State.PLAYING) {
                return "Playing";
            } else {
                return "Stopped";
            }
        }
    }

    public HashTable<string, Variant>? metadata {
        owned get {
            var _metadata = new HashTable<string, Variant> (null, null);

            Objects.Track track = Services.Player.instance ().current_track;
            if (track != null) {
                _metadata.insert ("mpris:artUrl", track.get_cover_file ());
                _metadata.insert ("xesam:title", track.title);
                _metadata.insert ("xesam:artist", track.album.artist.name);
            }

            return _metadata;
        }
    }

    public SoundIndicatorPlayer (DBusConnection connection) {
        Object (connection: connection);
    }

    construct {        
        Services.Player.instance ().current_track_changed.connect (() => {
            send_property_change ("Metadata", metadata);
        });

        Services.Player.instance ().state_changed.connect (() => {
            send_property_change ("PlaybackStatus", playback_status);
        });

        Services.Player.instance ().bind_property ("can_play", this, "can-play", BindingFlags.SYNC_CREATE);
        Services.Player.instance ().bind_property ("can_go_next", this, "can-go-next", BindingFlags.SYNC_CREATE);
        Services.Player.instance ().bind_property ("can_go_previous", this, "can-go-previous", BindingFlags.SYNC_CREATE);

        notify["can-play"].connect (() => send_property_change ("CanPlay", can_play));
        notify["can-go-next"].connect (() => send_property_change ("CanGoNext", can_go_next));
        notify["can-go-previous"].connect (() => send_property_change ("CanGoPrevious", can_go_previous));
    }

    private void send_property_change (string name, Variant variant) {
        var invalid_builder = new VariantBuilder (new VariantType ("as"));

        var builder = new VariantBuilder (VariantType.ARRAY);
        builder.add ("{sv}", name, variant);

        try {
            connection.emit_signal (
                null,
                "/org/mpris/MediaPlayer2",
                "org.freedesktop.DBus.Properties",
                "PropertiesChanged",
                new Variant (
                    "(sa{sv}as)",
                    "org.mpris.MediaPlayer2.Player",
                    builder,
                    invalid_builder
                )
            );
        } catch (Error e) {
            critical ("Could not send MPRIS property change: %s", e.message);
        }
    }

    public void PlayPause () throws Error {
        Services.Player.instance ().toggle_playing ();
    }

    public void Next () throws Error {
        Services.Player.instance ().next ();
    }

    public void Previous () throws Error {
        Services.Player.instance ().prev ();
    }
}