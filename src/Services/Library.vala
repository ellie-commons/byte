/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Services.Library : GLib.Object {
    Gee.ArrayList<Objects.Artist> _artists = null;
	public Gee.ArrayList<Objects.Artist> artists {
		get {
			if (_artists == null) {
				_artists = Services.Database.instance ().get_artists_collection ();
			}

			return _artists;
		}
	}

    Gee.ArrayList<Objects.Album> _albums = null;
	public Gee.ArrayList<Objects.Album> albums {
		get {
			if (_albums == null) {
				_albums = Services.Database.instance ().get_albums_collection ();
			}

			return _albums;
		}
	}

    Gee.ArrayList<Objects.Track> _tracks = null;
	public Gee.ArrayList<Objects.Track> tracks {
		get {
			if (_tracks == null) {
				_tracks = Services.Database.instance ().get_tracks_collection ();
			}

			return _tracks;
		}
	}

    public signal void artist_added (Objects.Artist artist);
    public signal void album_added (Objects.Album album);
    public signal void track_added (Objects.Track track);

    static GLib.Once<Services.Library> _instance;
    public static unowned Services.Library instance () {
        return _instance.once (() => {
            return new Services.Library ();
        });
    }

    public bool is_empty () {
        print ("tracks: %d\n".printf (tracks.size));
        return tracks.size <= 0;
    }

    public Objects.Artist? add_artist_if_not_exists (Objects.Artist artist) {
        Objects.Artist? return_value = null;
        lock (artists) {
            return_value = get_artist (artist.name);
            if (return_value == null) {
                artist.id = Uuid.string_random ();
                if (Services.Database.instance ().insert_artist (artist)) {
                    artists.add (artist);
			        artist_added (artist);

                    return_value = artist;
                }
            }
            return return_value;
        }
    }

    public Objects.Artist? get_artist (string name) {
        Objects.Artist? return_value = null;
        lock (_artists) {
            foreach (var artist in artists) {
                if (artist.name == name) {
                    return_value = artist;
                    break;
                }
            }
        }

        return return_value;
    }

    public Objects.Album? add_album_if_not_exists (Objects.Album album) {
        Objects.Album? return_value = null;
        lock (albums) {
            return_value = get_album (album.title);
            if (return_value == null) {
                album.id = Uuid.string_random ();
                if (Services.Database.instance ().insert_album (album)) {
                    albums.add (album);
			        album_added (album);

                    return_value = album;
                }
            }
            return return_value;
        }
    }

    public Objects.Album? get_album (string title) {
        Objects.Album? return_value = null;
        lock (_albums) {
            foreach (var album in albums) {
                if (album.title == title) {
                    return_value = album;
                    break;
                }
            }
        }

        return return_value;
    }

    public Objects.Track? add_track_if_not_exists (Objects.Track track) {
        Objects.Track? return_value = null;
        lock (tracks) {
            return_value = get_track (track.path);
            if (return_value == null) {
                track.id = Uuid.string_random ();
                if (Services.Database.instance ().insert_track (track)) {
                    tracks.add (track);
			        track_added (track);

                    return_value = track;
                }
            }
            return return_value;
        }
    }

    public Objects.Track? get_track (string path) {
        Objects.Track? return_value = null;
        lock (_tracks) {
            foreach (var track in tracks) {
                if (track.path == path) {
                    return_value = track;
                    break;
                }
            }
        }

        return return_value;
    }
}
