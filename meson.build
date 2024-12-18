# project name and programming language
project('io.github.ellie_commons.byte', 'vala', 'c', version: '0.1')

# Include Gnome and the translations module
gnome = import('gnome')
i18n = import('i18n')

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

## Set de config data
config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
  input: 'src/Config.vala.in',
  output: '@BASENAME@',
  configuration: config_data,
)

gresource = gnome.compile_resources(
  'as-resources',
  'data' / 'byte.gresource.xml',
  source_dir: 'data',
  c_name: 'as',
)

# List the dependencies we need
deps = [
  dependency('granite-7'),
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('sqlite3'),
  dependency('gstreamer-pbutils-1.0'),
  dependency('gstreamer-tag-1.0'),
  dependency('taglib_c'),
]

# Create a new executable, list the files we want to compile, and install
executable(
  meson.project_name(),
  config_file,
  gresource,
  'src/Application.vala',
  'src/MainWindow.vala',
  'src/Enum.vala',
  'src/Util.vala',

  'src/Objects/Album.vala',
  'src/Objects/Artist.vala',
  'src/Objects/Track.vala',
    
  'src/Services/Database.vala',
  'src/Services/Scanner.vala',
  'src/Services/Library.vala',
  'src/Services/Player.vala',
  'src/Services/EventBus.vala',

  'src/Views/Welcome.vala',
  'src/Views/Home.vala',
  'src/Views/RecentlyAdded.vala',
  'src/Views/Tracks.vala',

  'src/Widgets/Accordion.vala',
  'src/Widgets/HeaderBar.vala',
  'src/Widgets/MediaControl.vala',
  'src/Widgets/MediaCover.vala',
  'src/Widgets/Sidebar.vala',
  'src/Widgets/SidebarRow.vala',
  'src/Widgets/TrackRow.vala',

  dependencies: deps,
  install: true,
)

subdir('data')
subdir('po')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
