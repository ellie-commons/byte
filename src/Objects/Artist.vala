public class Objects.Artist : GLib.Object {
    public string id { get; set; default = ""; }
    public string name { get; set; default = ""; }

    public void to_string () {
        print ("Artist ID: %s\n", id);
        print ("Artist Name: %s\n", name);
    }
}