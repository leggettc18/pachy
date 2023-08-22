sources = [
    'Application.vala',
    'Settings.vala',
    'MainWindow.vala',
    'Dialogs/Authentication.vala',
    'Services/Mastodon.vala'
]

executable(
    meson.project_name(),
    gresource,
    sources,
    config_file,
    dependencies: dependencies,
    install: true
)
