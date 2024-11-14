
/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Views.Home : Adw.Bin {
    construct {
      child = new Gtk.Label ("HOME") {
         valign = CENTER,
         halign = CENTER
      };
    }
 }