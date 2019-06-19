public class Objects.Playlist : GLib.Object {
    public int id;
    public string title;
    public string note;
    public string added_date;
    public string updated_date;
    public int num_tracks;

    public Playlist (int id = 0,
                     string title = "",
                     string note = "",
                     string added_date = new GLib.DateTime.now_local ().to_string (),
                     string updated_date = new GLib.DateTime.now_local ().to_string (),
                     int num_tracks = 0) {
        this.id = id;
        this.title = title;
        this.note = note;
        this.added_date = added_date;
        this.updated_date = updated_date; 
        this.num_tracks = num_tracks;
    }
}