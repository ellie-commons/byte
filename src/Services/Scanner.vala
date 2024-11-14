/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public class Services.Scanner : GLib.Object {
    private Gst.PbUtils.Discoverer discoverer;
    string unknown = _("Unknown");

    public int counter = 0;
    public int counter_max = 0;
    public bool is_sync = false;
    
    public signal void sync_started ();
    public signal void sync_finished ();
    public signal void sync_progress (double fraction);

    static GLib.Once<Services.Scanner> _instance;
    public static unowned Services.Scanner instance () {
        return _instance.once (() => {
            return new Services.Scanner ();
        });
    }

    construct {
        try {
            discoverer = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (5 * Gst.SECOND));
            discoverer.start ();
            discoverer.discovered.connect (discovered);
        } catch (Error err) {
            warning (err.message);
        }
    }

    private void discovered (Gst.PbUtils.DiscovererInfo info, Error? err) {
        Idle.add (() => {
            string uri = info.get_uri ();

            if (info.get_result () != Gst.PbUtils.DiscovererResult.OK) {
                if (err != null) {
                    warning ("DISCOVER ERROR: '%d' %s %s\n(%s)", err.code, err.message, info.get_result ().to_string (), uri);
                }
            } else {
                var tags = info.get_tags ();

                if (tags != null) {
                    uint64 duration = info.get_duration ();
                    string o;
                    GLib.Date? d; 
                    Gst.DateTime? dt;
                    uint u;
                    double dou;

                    // TRACK OBJECT
                    var track = new Objects.Track ();
                    track.duration = duration;
                    track.path = uri;

                    if (tags.get_string (Gst.Tags.TITLE, out o)) {
                        track.title = o;
                    }

                    if (track.title.strip () == "") {
                        track.title = Path.get_basename (uri);
                    }
                    
                    if (tags.get_uint (Gst.Tags.TRACK_NUMBER, out u)) {
                        track.track = (int)u;
                    }
                    
                    if (tags.get_uint (Gst.Tags.ALBUM_VOLUME_NUMBER, out u)) {
                        track.disc = (int)u;
                    }

                    if (tags.get_string (Gst.Tags.COMPOSER, out o)) {
                        track.composer = o; 
                    }
                    
                    if (tags.get_string (Gst.Tags.GROUPING, out o)) {
                        track.grouping = o;
                    }
                    
                    if (tags.get_string (Gst.Tags.LYRICS, out o)) {
                        track.lyrics = o;
                    }

                    // BITRATE
                    var file = new TagLib.File (File.new_for_uri (uri).get_path ());
                    track.bitrate = file.audioproperties.bitrate;
                    track.samplerate = file.audioproperties.samplerate;
                    track.channels = file.audioproperties.channels;
                    
                    if (tags.get_uint (Gst.Tags.USER_RATING, out u)) {
                        track.rating = (int) u;
                    }

                    if (tags.get_double (Gst.Tags.BEATS_PER_MINUTE, out dou)) {
                        track.bpm = (int) dou.clamp (0, dou);
                    }

                    // ALBUM OBJECT
                    var album = new Objects.Album ();
                    if (tags.get_string (Gst.Tags.ALBUM, out o)) {
                        album.title = o;
                    }

                    if (album.title.strip () == "") {
                        var dir = Path.get_dirname (uri);
                        if (dir != null) {
                            album.title = Path.get_basename (dir);
                        } else {
                            album.title = unknown;
                        }
                    }

                    if (tags.get_date_time (Gst.Tags.DATE_TIME, out dt)) {
                        if (dt != null) {
                            album.year = dt.get_year ();
                            track.year = dt.get_year ();
                        } else if (tags.get_date (Gst.Tags.DATE, out d)) {
                            if (d != null) {
                                album.year = dt.get_year ();
                                track.year = dt.get_year ();
                            }
                        }
                    }

                    if (tags.get_string (Gst.Tags.GENRE, out o)) {
                        album.genre = o;
                        track.genre = o;
                    }

                    // ARTIST OBJECT
                    var artist = new Objects.Artist ();
                    if (tags.get_string (Gst.Tags.ALBUM_ARTIST, out o)) {
                        track.album_artist = o;
                        artist.name = o;
                    } else if (tags.get_string (Gst.Tags.ARTIST, out o)) {
                        artist.name = o;
                    }

                    if (artist.name.strip () == "") {
                        var dir = Path.get_dirname (Path.get_dirname (uri));
                        if (dir != null) {
                            artist.name = Path.get_basename (dir);
                        } else {
                            artist.name = unknown;
                        }
                    }

                    print ("Artist\n");
                    artist.to_string ();
                    print ("Album\n");
                    album.to_string ();
                    print ("Track\n");
                    track.to_string ();
                    print ("------------------------\n");
                    
                    discovered_new_item (artist, album, track);
                }
            }

            info.dispose ();

            return false;
        });
    }

    public void scan_local_files (string uri) {
        new Thread<void*> ("scan_local_files", () => {
            File directory = File.new_for_uri (uri.replace ("#", "%23"));
            try {
                var children = directory.enumerate_children ("standard::*," + FileAttribute.STANDARD_CONTENT_TYPE + "," + FileAttribute.STANDARD_IS_HIDDEN + "," + FileAttribute.STANDARD_IS_SYMLINK + "," + FileAttribute.STANDARD_SYMLINK_TARGET, GLib.FileQueryInfoFlags.NONE);
                FileInfo file_info = null;

                while ((file_info = children.next_file ()) != null) {
                    if (file_info.get_is_hidden ()) {
                        continue;
                    }

                    if (file_info.get_is_symlink ()) {
                        string target = file_info.get_symlink_target ();
                        var symlink = File.new_for_path (target);
                        var file_type = symlink.query_file_type (0);
                        if (file_type == FileType.DIRECTORY) {
                            scan_local_files (target);
                        }
                    } else if (file_info.get_file_type () == FileType.DIRECTORY) {
                        // Without usleep it crashes on smb:// protocol
                        if (!directory.get_uri ().has_prefix ("file://")) {
                            Thread.usleep (1000000);
                        }

                        scan_local_files (directory.get_uri () + "/" + file_info.get_name ());
                    } else {
                        string mime_type = file_info.get_content_type ();
                        if (is_audio_file (mime_type)) {
                            found_music_file (directory.get_uri () + "/" + file_info.get_name ().replace ("#", "%23"));
                        }
                    }
                }

                children.close ();
                children.dispose ();
            } catch (Error err) {
                warning ("%s\n%s", err.message, uri);
            }

            directory.dispose ();
            return null;
        });
    }

    public void found_music_file (string uri) {
        new Thread<void*> ("found_local_music_file", () => {
            Idle.add (() => {
                if (!Services.Database.instance ().music_file_exists (uri)) {
                    discoverer.discover_uri_async (uri);
                }

                return false;
            });

            return null;
        });
    }

    public static bool is_audio_file (string mime_type) {
        return mime_type.has_prefix ("audio/") && !mime_type.contains ("x-mpegurl") && !mime_type.contains ("x-scpls");
    }

    public void discovered_new_item (Objects.Artist _artist, Objects.Album _album, Objects.Track _track) {
        new Thread<void*> ("discovered_new_local_item", () => {
            if (counter <= 0) {
                sync_started ();
                is_sync = true;
            }

            counter++;
            counter_max++;

            Objects.Artist artist = Services.Library.instance ().add_artist_if_not_exists (_artist);

            _album.artist_id = artist.id;
            Objects.Album album = Services.Library.instance ().add_album_if_not_exists (_album);

            _track.album_id = album.id;
            Services.Library.instance ().add_track_if_not_exists (_track);
            return null;
        });
    }
}
