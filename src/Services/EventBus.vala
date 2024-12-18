/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

 public class Services.EventBus : GLib.Object {
    static GLib.Once<Services.EventBus> _instance;
    public static unowned Services.EventBus instance () {
        return _instance.once (() => {
            return new Services.EventBus ();
        });
    }

    public signal void select_view (ViewType view_type, string id = "");
    public signal void show_sidebar ();
 }