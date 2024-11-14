public class Objects.Track : GLib.Object {
    public string id { get; set; default = ""; }
    public string album_id { get; set; default = ""; }
    public int track_order { get; set; default = 0; }
    public int track { get; set; default = 0; }
    public int disc { get; set; default = 0; }
    public int play_count { get; set; default = 0; }
    public int is_favorite { get; set; default = 0; }
    public int bitrate { get; set; default = 0; }
    public int bpm { get; set; default = 0; }
    public int rating { get; set; default = 0; }
    public int samplerate { get; set; default = 0; }
    public int channels { get; set; default = 0; }
    public int year { get; set; default = 0; }
    public int playlist_id { get; set; default = 0; }
    public uint64 duration { get; set; default = 0; }
    public string path { get; set; default = ""; }
    public string title { get; set; default = ""; }
    public string favorite_added { get; set; default = ""; }
    public string last_played { get; set; default = ""; }
    public string album_title { get; set; default = ""; }
    public string artist_name { get; set; default = ""; }
    public string composer { get; set; default = ""; }
    public string grouping { get; set; default = ""; }
    public string comment { get; set; default = ""; }
    public string lyrics { get; set; default = ""; }
    public string genre { get; set; default = ""; }
    public string album_artist { get; set; default = ""; }
    public string playlist_title { get; set; default = ""; }
    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string playlist_added { get; set; default = ""; }

    public void to_string () {
        print ("ID: %s\n", id);
        print ("Album ID: %s\n", album_id);
        print ("Track Order: %d\n", track_order);
        print ("Track: %d\n", track);
        print ("Disc: %d\n", disc);
        print ("Play Count: %d\n", play_count);
        print ("Is Favorite: %d\n", is_favorite);
        print ("Bitrate: %d\n", bitrate);
        print ("BPM: %d\n", bpm);
        print ("Rating: %d\n", rating);
        print ("Samplerate: %d\n", samplerate);
        print ("Channels: %d\n", channels);
        print ("Year: %d\n", year);
        print ("Playlist ID: %d\n", playlist_id);
        print ("Duration: %" + "u64" + "u\n", duration);
        print ("Path: %s\n", path);
        print ("Title: %s\n", title);
        print ("Favorite Added: %s\n", favorite_added);
        print ("Last Played: %s\n", last_played);
        print ("Album Title: %s\n", album_title);
        print ("Artist Name: %s\n", artist_name);
        print ("Composer: %s\n", composer);
        print ("Grouping: %s\n", grouping);
        print ("Comment: %s\n", comment);
        print ("Lyrics: %s\n", lyrics);
        print ("Genre: %s\n", genre);
        print ("Album Artist: %s\n", album_artist);
        print ("Playlist Title: %s\n", playlist_title);
        print ("Date Added: %s\n", date_added);
        print ("Playlist Added: %s\n", playlist_added);
    }
}
