/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Widgets.MediaCover : Adw.Bin {
   private Gtk.Image image;

   public int size {
      set {
         image.pixel_size = value;
      }

      get {
         return image.pixel_size;
      }
   }

   public MediaCover () {
      Object (
         overflow: Gtk.Overflow.HIDDEN,
         valign: Gtk.Align.CENTER,
         halign: Gtk.Align.CENTER
      );
   }

   construct {
      add_css_class (Granite.STYLE_CLASS_CARD);
      add_css_class (Granite.STYLE_CLASS_ROUNDED);
   
      image = new Gtk.Image ();

      child = image;
   }

   public void set_track (Objects.Track track) {
      try {
         image.set_from_file (track.get_cover_path ());
      } catch (Error e) {
         //  show_default (pixel_size);
      }
   }
 }