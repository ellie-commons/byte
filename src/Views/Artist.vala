public class Views.Artist : Gtk.EventBox {
    private static int QUEUE_TYPE = 5;

    public Objects.Artist artist { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Image image_cover;
    private Gtk.ListBox listbox;
    private Gtk.FlowBox flowbox;

    public Gee.ArrayList<Objects.Track?> all_tracks;
    private Gee.ArrayList<Objects.Album?> all_albums;

    public Artist (Objects.Artist artist) {
        Object (
            artist: artist
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        get_style_context ().add_class ("w-round");

        var back_button = new Gtk.Button.from_icon_name ("byte-arrow-back-symbolic", Gtk.IconSize.MENU);
        back_button.can_focus = false;
        back_button.margin = 3;
        back_button.margin_bottom = 6;
        back_button.margin_top = 6;
        back_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        back_button.get_style_context ().add_class ("label-color-primary");

        var center_label = new Gtk.Label (_("Artist"));
        center_label.use_markup = true;
        center_label.valign = Gtk.Align.CENTER;
        center_label.get_style_context ().add_class ("h3");
        center_label.get_style_context ().add_class ("label-color-primary");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_box.get_style_context ().add_class (Gtk.STYLE_CLASS_BACKGROUND);
        header_box.pack_start (back_button, false, false, 0);
        header_box.set_center_widget (center_label);

        image_cover = new Gtk.Image ();
        image_cover.expand = true;

        name_label = new Gtk.Label (artist.name);
        name_label.halign = Gtk.Align.CENTER;
        name_label.valign = Gtk.Align.CENTER;
        name_label.wrap = true;
        name_label.wrap_mode = Pango.WrapMode.CHAR; 
        name_label.justify = Gtk.Justification.FILL;
        name_label.get_style_context ().add_class ("font-bold");
        name_label.get_style_context ().add_class ("h3");

        var most_played_label = new Gtk.Label ("<b>%s</b>".printf (_("Most Played")));
        most_played_label.get_style_context ().add_class ("label-color-primary");
        most_played_label.get_style_context ().add_class ("h3");
        most_played_label.margin_start = 6;
        most_played_label.halign = Gtk.Align.START;
        most_played_label.use_markup = true;

        listbox = new Gtk.ListBox ();
        //listbox.hexpand = true;

        var albums_label = new Gtk.Label ("<b>%s</b>".printf (_("Albums")));
        albums_label.get_style_context ().add_class ("label-color-primary");
        albums_label.get_style_context ().add_class ("h3");
        albums_label.margin_start = 7;
        albums_label.halign = Gtk.Align.START;
        albums_label.use_markup = true;

        flowbox = new Gtk.FlowBox ();
        flowbox.homogeneous = true;
        flowbox.min_children_per_line = 2;
        flowbox.max_children_per_line = 2;

        var detail_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        detail_box.get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);
        detail_box.pack_start (image_cover, false, false, 6);
        detail_box.pack_start (name_label, false, false, 6);
        detail_box.pack_start (most_played_label, false, false, 3);
        detail_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);
        detail_box.pack_start (listbox, false, false, 0);
        detail_box.pack_start (albums_label, false, false, 3);
        //detail_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);
        detail_box.pack_start (flowbox, false, false, 0);

        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.margin_bottom = 48;
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.expand = true;
        main_scrolled.add (detail_box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (header_box, false, false, 0);
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);
        main_box.pack_start (main_scrolled, true, true, 0);

        add (main_box);
        
        show_all ();

        Timeout.add (250, () => {
            int width = main_box.get_allocated_width ();
            int height = main_box.get_allocated_height ();

            print ("width: %i\n".printf (width));
            print ("height: %i\n".printf (height));

            var pixbuf = new Gdk.Pixbuf.from_file (
                GLib.Path.build_filename (Byte.utils.COVER_FOLDER, ("artist-%i.jpg").printf (artist.id))
            );

            if (height < width) {
                var pix = pixbuf.scale_simple (width, width, Gdk.InterpType.BILINEAR);
                image_cover.pixbuf = new Gdk.Pixbuf.subpixbuf (pix, 0, (int)(pix.height - height) / 2, width, height);
            } else {
                var pix = pixbuf.scale_simple (height, height, Gdk.InterpType.BILINEAR);
                image_cover.pixbuf = new Gdk.Pixbuf.subpixbuf (pix, (int)(pix.width - width) / 2, 0, width, height);
            }
        });

        if (Byte.scan_service.is_sync == false) {
            int item_max = 5;
            all_tracks = Byte.database.get_all_tracks_by_artist (artist.id);
            if (item_max > all_tracks.size) {
                item_max = all_tracks.size;
            }
    
            for (int i = 0; i < item_max; i++) {
                var row = new Widgets.TrackRow (all_tracks [i]);
    
                listbox.add (row);
                listbox.show_all ();
            }

            all_albums = Byte.database.get_all_albums_by_artist (artist.id);
            foreach (var item in all_albums) {
                var row = new Widgets.AlbumArtistChild (item);
                flowbox.add (row);
                flowbox.show_all ();
            }
        }
        
        back_button.clicked.connect (() => {
            Byte.navCtrl.pop ();
        });

        listbox.row_activated.connect ((row) => {
            var item = row as Widgets.TrackRow;
            
            Byte.utils.play_queue_start_with_track (all_tracks, QUEUE_TYPE, item.track, 0, artist.id);
        });

        flowbox.child_activated.connect ((child) => {
            var item = child as Widgets.AlbumArtistChild;

            if (!Byte.navCtrl.has_key ("album-%i".printf (item.album.id))) {
                var album_view = new Views.Album (item.album);
                Byte.navCtrl.add_named (album_view, "album-%i".printf (item.album.id));
            }

            Byte.navCtrl.push ("album-%i".printf (item.album.id));
        });
    }
}
