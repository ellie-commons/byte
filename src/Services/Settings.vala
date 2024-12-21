/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */
 
public class Services.Settings : GLib.Object {
    public GLib.Settings settings;

    static GLib.Once<Services.Settings> _instance;
    public static unowned Services.Settings instance () {
        return _instance.once (() => {
            return new Services.Settings ();
        });
    }

    public Settings () {
        settings = new GLib.Settings ("io.github.ellie_commons.byte");
    }

    public void reset_settings () {
        var schema_source = GLib.SettingsSchemaSource.get_default ();
        SettingsSchema schema = schema_source.lookup ("io.github.ellie_commons.byte", true);

        foreach (string key in schema.list_keys ()) {
            settings.reset (key);
        }
    }

    public bool get_boolean (string key) {
        return settings.get_boolean (key);
    }
 }