/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 Alain <alainmh23@gmail.com>
 */

public enum ViewType {
    HOME,
    RECENTLY_ADDED,
    ARTISTS,
    ALBUMS,
    SONGS,
    PLAYLIST;

    public string get_title () {
        switch (this) {
            case HOME: return _("Home");
            case RECENTLY_ADDED: return _("Recently Added");
            case ARTISTS: return _("Artists");
            case ALBUMS: return _("Albums");
            case SONGS: return _("Songs");
            case PLAYLIST: return _("View All");
        }

        return "";
    }

    public string get_icon () {
        switch (this) {
            case HOME: return "go-home-symbolic";
            case RECENTLY_ADDED: return "preferences-system-time-symbolic";
            case ARTISTS: return "avatar-default-symbolic";
            case ALBUMS: return "folder-symbolic";
            case SONGS: return "folder-music-symbolic";
            case PLAYLIST: return "view-grid-symbolic";
        }
        return "";
    }
}