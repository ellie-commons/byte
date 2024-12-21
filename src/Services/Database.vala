/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public class Services.Database : GLib.Object {
    private Sqlite.Database db;
    private string db_path;
    private string errormsg;
    private string sql;

    static GLib.Once<Services.Database> _instance;
    public static unowned Services.Database instance () {
        return _instance.once (() => {
            return new Services.Database ();
        });
    }

    construct {
        db_path = Environment.get_user_data_dir () + "/io.github.ellie_commons.byte/database.db";
    }

    public signal void opened ();

    public void init_database () {
        Sqlite.Database.open (db_path, out db);

        create_tables ();
        opened ();
    }

    private void create_tables () {
        sql = """
                CREATE TABLE IF NOT EXISTS Artists (
                    id              TEXT PRIMARY KEY,
                    name            TEXT,
                    CONSTRAINT unique_label UNIQUE (name)
                );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
                CREATE TABLE IF NOT EXISTS Albums (
                    id              TEXT PRIMARY KEY,
                    artist_id       TEXT,
                    year            INT,
                    title           TEXT,
                    genre           TEXT,
                    CONSTRAINT unique_album UNIQUE (artist_id, title),
                    FOREIGN KEY (artist_id) REFERENCES artists (id) ON DELETE CASCADE
                );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = """
                CREATE TABLE IF NOT EXISTS Tracks (
                    id             TEXT PRIMARY KEY,
                    album_id       TEXT NOT NULL,
                    track          INT,
                    disc           INT,
                    play_count     INT,
                    is_favorite    INT,
                    duration       INT,
                    samplerate     INT,
                    channels       INT,
                    bitrate        INT,
                    bpm            INT,
                    rating         INT,
                    year           INT,
                    path           TEXT,
                    title          TEXT,
                    date_added     TEXT,
                    favorite_added TEXT,
                    last_played    TEXT,
                    composer       TEXT,
                    grouping       TEXT,
                    comment        TEXT,
                    lyrics         TEXT,
                    genre          TEXT,
                    CONSTRAINT unique_track UNIQUE (path),
                    FOREIGN KEY (album_id) REFERENCES albums (id) ON DELETE CASCADE
            );
        """;

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }

        sql = "PRAGMA foreign_keys = ON;";

        if (db.exec (sql, null, out errormsg) != Sqlite.OK) {
            warning (errormsg);
        }
    }

    public void clear_database () {
		File db_file = File.new_for_path (db_path);

		if (db_file.query_exists ()) {
			try {
				db_file.delete ();
			} catch (Error err) {
				warning (err.message);
			}
		}
	}


    public bool music_file_exists (string uri) {
        bool file_exists = false;
        Sqlite.Statement stmt;

        sql = "SELECT COUNT (*) FROM Tracks WHERE path = $path";

        db.prepare_v2 (sql, sql.length, out stmt);
        set_parameter_str (stmt, "$path", uri);

        if (stmt.step () == Sqlite.ROW) {
            file_exists = stmt.column_int (0) > 0;
        }

        return file_exists;
    }
   
    public Gee.ArrayList<Objects.Artist> get_artists_collection () {
        Gee.ArrayList<Objects.Artist> return_value = new Gee.ArrayList<Objects.Artist> ();

		Sqlite.Statement stmt;

		sql = """
            SELECT * FROM Artists;
        """;

		db.prepare_v2 (sql, sql.length, out stmt);

		while (stmt.step () == Sqlite.ROW) {
			return_value.add (_fill_artist (stmt));
		}

		return return_value;
    }

    private Objects.Artist _fill_artist (Sqlite.Statement stmt) {
		Objects.Artist return_value = new Objects.Artist ();
		return_value.id = stmt.column_text (0);
		return_value.name = stmt.column_text (1);
		return return_value;
	}

    public bool insert_artist (Objects.Artist artist) {
        Sqlite.Statement stmt;

		sql = """
            INSERT OR IGNORE INTO Artists (id, name) VALUES ($id, $name);
        """;

		db.prepare_v2 (sql, sql.length, out stmt);
		set_parameter_str (stmt, "$id", artist.id);
		set_parameter_str (stmt, "$name", artist.name);

		if (stmt.step () != Sqlite.DONE) {
			warning ("Error: %d: %s", db.errcode (), db.errmsg ());
		}

		return stmt.step () == Sqlite.DONE;
    }

    public Gee.ArrayList<Objects.Album> get_albums_collection () {
        Gee.ArrayList<Objects.Album> return_value = new Gee.ArrayList<Objects.Album> ();

		Sqlite.Statement stmt;

		sql = """
            SELECT * FROM Albums;
        """;

		db.prepare_v2 (sql, sql.length, out stmt);

		while (stmt.step () == Sqlite.ROW) {
			return_value.add (_fill_album (stmt));
		}

		return return_value;
    }

    private Objects.Album _fill_album (Sqlite.Statement stmt) {
		Objects.Album return_value = new Objects.Album ();
		return_value.id = stmt.column_text (0);
		return_value.artist_id = stmt.column_text (1);
        return_value.year = stmt.column_int (2);
        return_value.title = stmt.column_text (3);
        return_value.genre = stmt.column_text (4);
		return return_value;
	}

    public bool insert_album (Objects.Album album) {
        Sqlite.Statement stmt;
		sql = """
            INSERT OR IGNORE INTO Albums (id, artist_id, year, title, genre)
            VALUES ($id, $artist_id, $year, $title, $genre);
        """;

		db.prepare_v2 (sql, sql.length, out stmt);
		set_parameter_str (stmt, "$id", album.id);
		set_parameter_str (stmt, "$artist_id", album.artist_id);
        set_parameter_int (stmt, "$year", album.year);
        set_parameter_str (stmt, "$title", album.title);
        set_parameter_str (stmt, "$genre", album.genre);

		if (stmt.step () != Sqlite.DONE) {
			warning ("Error: %d: %s", db.errcode (), db.errmsg ());
		}

		return stmt.step () == Sqlite.DONE;
    }

    public Gee.ArrayList<Objects.Track> get_tracks_collection () {
        Gee.ArrayList<Objects.Track> return_value = new Gee.ArrayList<Objects.Track> ();

		Sqlite.Statement stmt;

		sql = """
            SELECT * FROM Tracks;
        """;

		db.prepare_v2 (sql, sql.length, out stmt);

		while (stmt.step () == Sqlite.ROW) {
			return_value.add (_fill_track (stmt));
		}

		return return_value;
    }

    private Objects.Track _fill_track (Sqlite.Statement stmt) {
		Objects.Track return_value = new Objects.Track ();
		return_value.id = stmt.column_text (0);
        return_value.album_id = stmt.column_text (1);
        return_value.track = stmt.column_int (2);
        return_value.disc = stmt.column_int (3);
        return_value.play_count = stmt.column_int (4);
        return_value.is_favorite = stmt.column_int (5);
        return_value.duration = stmt.column_int64 (6);
        return_value.samplerate = stmt.column_int (7);
        return_value.channels = stmt.column_int (8);
        return_value.bitrate = stmt.column_int (9);
        return_value.bpm = stmt.column_int (10);
        return_value.rating = stmt.column_int (11);
        return_value.year = stmt.column_int (12);
        return_value.path = stmt.column_text (13);
        return_value.title = stmt.column_text (14);
        return_value.date_added = stmt.column_text (15);
        return_value.favorite_added = stmt.column_text (16);
        return_value.last_played = stmt.column_text (17);
        return_value.composer = stmt.column_text (18);
        return_value.grouping = stmt.column_text (19);
        return_value.comment = stmt.column_text (20);
        return_value.lyrics = stmt.column_text (21);
        return_value.genre = stmt.column_text (22);
		return return_value;
	}

    public bool insert_track (Objects.Track track) {
        Sqlite.Statement stmt;
		sql = """
            INSERT OR IGNORE INTO Tracks (id, album_id, track, disc, play_count, is_favorite, duration,
            samplerate, channels, bitrate, bpm, rating, year, path, title, date_added, favorite_added,
            last_played, composer, grouping, comment, lyrics, genre)
            VALUES ($id, $album_id, $track, $disc, $play_count, $is_favorite, $duration,
            $samplerate, $channels, $bitrate, $bpm, $rating, $year, $path, $title, $date_added, $favorite_added,
            $last_played, $composer, $grouping, $comment, $lyrics, $genre);
        """;

		db.prepare_v2 (sql, sql.length, out stmt);
		set_parameter_str (stmt, "$id", track.id);
		set_parameter_str (stmt, "$album_id", track.album_id);
        set_parameter_int (stmt, "$track", track.track);
        set_parameter_int (stmt, "$disc", track.disc);
        set_parameter_int (stmt, "$play_count", track.play_count);
        set_parameter_int (stmt, "$is_favorite", track.is_favorite);
        set_parameter_int64 (stmt, "$duration", (int64) track.duration);
        set_parameter_int (stmt, "$samplerate", track.samplerate);
        set_parameter_int (stmt, "$channels", track.channels);
        set_parameter_int (stmt, "$bitrate", track.bitrate);
        set_parameter_int (stmt, "$bpm", track.bpm);
        set_parameter_int (stmt, "$rating", track.rating);
        set_parameter_int (stmt, "$year", track.year);
        set_parameter_str (stmt, "$path", track.path);
        set_parameter_str (stmt, "$title", track.title);
        set_parameter_str (stmt, "$date_added", track.date_added);
        set_parameter_str (stmt, "$favorite_added", track.favorite_added);
        set_parameter_str (stmt, "$last_played", track.last_played);
        set_parameter_str (stmt, "$composer", track.composer);
        set_parameter_str (stmt, "$grouping", track.grouping);
        set_parameter_str (stmt, "$comment", track.comment);
        set_parameter_str (stmt, "$lyrics", track.lyrics);
        set_parameter_str (stmt, "$genre", track.genre);

		if (stmt.step () != Sqlite.DONE) {
			warning ("Error: %d: %s", db.errcode (), db.errmsg ());
		}

		return stmt.step () == Sqlite.DONE;
    }

    public bool update_track_count (Objects.Track track) {
        Sqlite.Statement stmt;

		sql = """
            UPDATE tracks SET play_count = $play_count, last_played = $last_played WHERE id = $id;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);
		set_parameter_int (stmt, "$play_count", track.play_count);
        set_parameter_str (stmt, "$last_played", track.last_played);
        set_parameter_str (stmt, "$id", track.id);

        if (stmt.step () != Sqlite.DONE) {
			warning ("Error: %d: %s", db.errcode (), db.errmsg ());
		}

		return stmt.step () == Sqlite.DONE;
    }

    // Utils
    private void set_parameter_str (Sqlite.Statement? stmt, string par, string val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_text (par_position, val);
    }

    private void set_parameter_int64 (Sqlite.Statement? stmt, string par, int64 val) {
		int par_position = stmt.bind_parameter_index (par);
		stmt.bind_int64 (par_position, val);
	}

    private void set_parameter_int (Sqlite.Statement? stmt, string par, int val) {
		int par_position = stmt.bind_parameter_index (par);
		stmt.bind_int (par_position, val);
	}
}
