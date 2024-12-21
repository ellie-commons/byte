/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public class Util : GLib.Object {
    public static string MAIN_FOLDER = Environment.get_user_data_dir () + "/io.github.ellie_commons.byte";
    public static string COVER_FOLDER = Environment.get_user_data_dir () + "/io.github.ellie_commons.byte/covers";

    public static string get_cover_path () {
        return Environment.get_user_data_dir () + "/io.github.ellie_commons.byte/covers";
    }

    public string get_cover_file (int track_id) {
        var cover_path = GLib.Path.build_filename (COVER_FOLDER, ("track-%i.jpg").printf (track_id));
        return "file://" + cover_path;
    }
}