/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.MediaCover : Adw.Bin {
   public int size { get; construct; }
   private Gtk.Image image;

   public MediaCover (int size) {
      Object (
         size: size,
         overflow: Gtk.Overflow.HIDDEN,
         valign: Gtk.Align.CENTER,
         halign: Gtk.Align.CENTER
      );
   }

   construct {
      add_css_class (Granite.STYLE_CLASS_CARD);
      add_css_class (Granite.STYLE_CLASS_ROUNDED);
   
      image = new Gtk.Image () {
         pixel_size = size
      };

      child = image;
   }

   public void set_track (Objects.Track track) {
      try {
         image.set_from_file (
            GLib.Path.build_filename (Util.get_cover_path (), ("album-%s.jpg").printf (track.album.id))
         );
      } catch (Error e) {
         //  show_default (pixel_size);
      }
   }
 }