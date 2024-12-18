public class Objects.Album : GLib.Object {
    public string id { get; set; }
    public string artist_id { get; set; }
    public int year { get; set; }
    public string title { get; set; }
    public string genre { get; set; }

    Objects.Artist? _artist;
    public Objects.Artist artist {
        get {
            if (_artist == null) {
                _artist = Services.Library.instance ().get_artist (artist_id);
            }
            
            return _artist;
        }
    }

    public void to_string () {
        print ("Album ID: %s\n", id);
        print ("Artist ID: %s\n", artist_id);
        print ("Year: %d\n", year);
        print ("Title: %s\n", title);
        print ("Genre: %s\n", genre);
    }
}