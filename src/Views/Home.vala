
/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public class Views.Home : Adw.Bin {
   private Gtk.FlowBox artit_flowbox;
   private Gtk.FlowBox recently_added_flowbox;
   private Gtk.FlowBox recently_played_flowbox;

   private Gee.HashMap<string, Widgets.TrackChild> recently_added_map = new Gee.HashMap<string, Widgets.TrackChild> ();
   private Gee.ArrayList<Objects.Track> recently_added_list = new Gee.ArrayList<Objects.Track> ();
   public uint recently_added_timeout_id  = 0;

   private Gee.HashMap<string, Widgets.TrackChild> recently_played_map = new Gee.HashMap<string, Widgets.TrackChild> ();
   private Gee.ArrayList<Objects.Track> recently_played_list = new Gee.ArrayList<Objects.Track> ();

   private int MAX_ITEMS = 8;

   construct {
      var recently_added_label = new Granite.HeaderLabel (_("Recently Added")) {
         secondary_text = _("Discover the latest songs added to your collection"),
         margin_start = 9,
         halign = START
      };

      recently_added_flowbox = new Gtk.FlowBox () {
         margin_top = 6,
         margin_bottom = 6,
         margin_start = 6,
         margin_end = 6,
         min_children_per_line = 2,
         column_spacing = 6
      };

      var recently_played_label = new Granite.HeaderLabel (_("Recently Played")) {
         secondary_text = _("Revisit the tracks you’ve been enjoying lately"),
         margin_start = 9,
         halign = START
      };

      recently_played_flowbox = new Gtk.FlowBox () {
         margin_top = 6,
         margin_bottom = 6,
         margin_start = 6,
         margin_end = 6,
         min_children_per_line = 2,
         column_spacing = 6
      };

      var artist_label = new Granite.HeaderLabel (_("Artist")) {
         secondary_text = _("Find your next musical inspiration here"),
         margin_start = 9,
         halign = START
      };

      artit_flowbox = new Gtk.FlowBox () {
         margin_top = 6,
         margin_bottom = 6,
         margin_start = 6,
         margin_end = 6,
         min_children_per_line = 3
      };

      var content_box = new Gtk.Box (VERTICAL, 0) {
         margin_start = 6,
         margin_end = 6
      };
      content_box.append (recently_added_label);
      content_box.append (recently_added_flowbox);
      content_box.append (recently_played_label);
      content_box.append (recently_played_flowbox);
      content_box.append (artist_label);
      content_box.append (artit_flowbox);

      var toolbar_view = new Adw.ToolbarView () {
         content = content_box
      };
      toolbar_view.add_top_bar (new Widgets.HeaderBar ());

      child = toolbar_view;
      add_artist ();
      add_recently_added ();
      add_recently_played ();

      recently_added_flowbox.child_activated.connect ((_child) => {
         var child = (Widgets.TrackChild) _child;
         Services.Player.instance ().set_tracks (
            recently_added_list,
             Services.Settings.instance ().settings.get_boolean ("shuffle-mode"),
             child.track
         );
     });

     recently_played_flowbox.child_activated.connect ((_child) => {
         var child = (Widgets.TrackChild) _child;
         Services.Player.instance ().set_tracks (
            recently_played_list,
            Services.Settings.instance ().settings.get_boolean ("shuffle-mode"),
            child.track
         );
      });

      Services.Scanner.instance ().sync_finished.connect (() => {
         add_recently_added ();
      });
   }

   private void add_artist () {
      foreach (Objects.Artist artist in Services.Library.instance ().artists) {
         var avatar_avatar = new Adw.Avatar (32, artist.name, true);

         var artist_label = new Gtk.Label (artist.name) {
            wrap = true,
            justify = CENTER
         };
         artist_label.add_css_class ("small-label");
         artist_label.add_css_class ("font-bold");

         var artist_box = new Gtk.Box (VERTICAL, 6) {
            hexpand = true,
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
         };
         artist_box.append (avatar_avatar);
         artist_box.append (artist_label);

         artit_flowbox.append (artist_box);
      }
   }

   private void add_recently_added () {
      if (recently_added_timeout_id != 0) {
			GLib.Source.remove (recently_added_timeout_id);
		}

      recently_added_timeout_id = Timeout.add (500, () => {
			recently_added_timeout_id = 0;

         foreach (Widgets.TrackChild child in recently_added_map.values) {
            child.hide_destroy ();
         }
   
         recently_added_map.clear ();
         
         recently_added_list = Services.Library.instance ().get_tracks_recently_added ();
         foreach (Objects.Track track in recently_added_list) {
            if (recently_added_map.size < MAX_ITEMS) {
               recently_added_map[track.id] = new Widgets.TrackChild (track);
               recently_added_flowbox.append (recently_added_map[track.id]);
            }
         }

         return GLib.Source.REMOVE;
      });
   }

   private void add_recently_played () {
      foreach (Widgets.TrackChild child in recently_played_map.values) {
         child.hide_destroy ();
      }

      recently_played_map.clear ();
      
      recently_played_list = Services.Library.instance ().get_tracks_recently_played ();
      foreach (Objects.Track track in recently_played_list) {
         if (recently_played_map.size < MAX_ITEMS && !recently_played_map.has_key (track.id)) {
            recently_played_map[track.id] = new Widgets.TrackChild (track);
            recently_played_flowbox.append (recently_played_map[track.id]);
         }
      }
   }
}