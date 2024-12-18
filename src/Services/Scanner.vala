/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public class Services.Scanner : GLib.Object {
    private Gst.PbUtils.Discoverer discoverer;
    private Gst.PbUtils.Discoverer discoverer_cover;
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

            discoverer_cover = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (5 * Gst.SECOND));
        } catch (Error err) {
            warning (err.message);
        }

        Services.Library.instance ().track_added.connect (() => {
            counter--;
            sync_progress (((double) counter_max - (double) counter) / (double) counter_max);
            if (counter <= 0) {
                sync_finished ();
                is_sync = false;
                counter_max = 0;
            }
        });
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
        new Thread<void*> ("found_music_file", () => {
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
        new Thread<void*> ("discovered_new_item", () => {
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

            save_cover (_track);

            return null;
        });
    }

    private void save_cover (Objects.Track track) {
        try {
            var info = discoverer_cover.discover_uri (track.path);
            read_info (info, track);
        } catch (Error err) {
            critical ("%s - %s, Error while importing …".printf (
                track.album.artist.name, track.title
            ));
        }
    }

    private void read_info (Gst.PbUtils.DiscovererInfo info, Objects.Track track) {
        string uri = info.get_uri ();
        bool gstreamer_discovery_successful = false;
        switch (info.get_result ()) {
            case Gst.PbUtils.DiscovererResult.OK:
                gstreamer_discovery_successful = true;
            break;

            case Gst.PbUtils.DiscovererResult.URI_INVALID:
                warning ("GStreamer could not import '%s': invalid URI.", uri);
            break;

            case Gst.PbUtils.DiscovererResult.ERROR:
                warning ("GStreamer could not import '%s'", uri);
            break;

            case Gst.PbUtils.DiscovererResult.TIMEOUT:
                warning ("GStreamer could not import '%s': Discovery timed out.", uri);
            break;

            case Gst.PbUtils.DiscovererResult.BUSY:
                warning ("GStreamer could not import '%s': Already discovering a file.", uri);
            break;

            case Gst.PbUtils.DiscovererResult.MISSING_PLUGINS:
                warning ("GStreamer could not import '%s': Missing plugins.", uri);
            break;
        }

        if (gstreamer_discovery_successful) {
            Idle.add (() => {
                Gdk.Pixbuf pixbuf = null;
                var tag_list = info.get_tags ();
                var sample = get_cover_sample (tag_list);

                if (sample == null) {
                    tag_list.get_sample_index (Gst.Tags.PREVIEW_IMAGE, 0, out sample);
                }

                if (sample != null) {
                    var buffer = sample.get_buffer ();

                    if (buffer != null) {
                        pixbuf = get_pixbuf_from_buffer (buffer);
                        if (pixbuf != null) {
                            save_cover_pixbuf (pixbuf, track);
                        }
                    }

                    debug ("Final image buffer is NULL for '%s'", info.get_uri ());
                } else {
                    debug ("Image sample is NULL for '%s'", info.get_uri ());
                }

                return false;
            });
        }
    }

    private Gst.Sample? get_cover_sample (Gst.TagList tag_list) {
        Gst.Sample cover_sample = null;
        Gst.Sample sample;
        for (int i = 0; tag_list.get_sample_index (Gst.Tags.IMAGE, i, out sample); i++) {
            var caps = sample.get_caps ();
            unowned Gst.Structure caps_struct = caps.get_structure (0);
            int image_type = Gst.Tag.ImageType.UNDEFINED;
            caps_struct.get_enum ("image-type", typeof (Gst.Tag.ImageType), out image_type);
            if (image_type == Gst.Tag.ImageType.UNDEFINED && cover_sample == null) {
                cover_sample = sample;
            } else if (image_type == Gst.Tag.ImageType.FRONT_COVER) {
                return sample;
            }
        }

        return cover_sample;
    }

    private Gdk.Pixbuf? get_pixbuf_from_buffer (Gst.Buffer buffer) {
        Gst.MapInfo map_info;

        if (!buffer.map (out map_info, Gst.MapFlags.READ)) {
            warning ("Could not map memory buffer");
            return null;
        }

        Gdk.Pixbuf pix = null;

        try {
            var loader = new Gdk.PixbufLoader ();

            if (loader.write (map_info.data) && loader.close ())
                pix = loader.get_pixbuf ();
        } catch (Error err) {
            warning ("Error processing image data: %s", err.message);
        }

        buffer.unmap (map_info);

        return pix;
    }

    private void save_cover_pixbuf (Gdk.Pixbuf p, Objects.Track track) {
        Idle.add (() => {
            Gdk.Pixbuf ? pixbuf = align_and_scale_pixbuf (p, 256);

            try {
                string album_path = GLib.Path.build_filename (Util.get_cover_path (), ("album-%s.jpg").printf (track.album.id));
                if (pixbuf.save (album_path, "jpeg", "quality", "100")) {
                    //  Byte.database.updated_album_cover (track.album_id);
                }
            } catch (Error err) {
                warning (err.message);
            }

            return false;
        });
    }

    private Gdk.Pixbuf? align_and_scale_pixbuf (Gdk.Pixbuf p, int size) {
        Gdk.Pixbuf ? pixbuf = p;
        if (pixbuf.width != pixbuf.height) {
            if (pixbuf.width > pixbuf.height) {
                int dif = (pixbuf.width - pixbuf.height) / 2;
                pixbuf = new Gdk.Pixbuf.subpixbuf (pixbuf, dif, 0, pixbuf.height, pixbuf.height);
            } else {
                int dif = (pixbuf.height - pixbuf.width) / 2;
                pixbuf = new Gdk.Pixbuf.subpixbuf (pixbuf, 0, dif, pixbuf.width, pixbuf.width);
            }
        }

        pixbuf = pixbuf.scale_simple (size, size, Gdk.InterpType.BILINEAR);

        return pixbuf;
    }
}
