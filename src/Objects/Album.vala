public class Objects.Album : GLib.Object {
    public string id { get; set; }
    public string artist_id { get; set; }
    public int year { get; set; }
    public string title { get; set; }
    public string genre { get; set; }

    public void to_string () {
        print ("Album ID: %s\n", id);
        print ("Artist ID: %s\n", artist_id);
        print ("Year: %d\n", year);
        print ("Title: %s\n", title);
        print ("Genre: %s\n", genre);
    }
}