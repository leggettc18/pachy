project(
    'com.github.leggettc18.pachy',
    'vala', 'c',
    version: '1.0',
    meson_version: '>=0.58.0'
)

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

devel = get_option('devel')

config_data = configuration_data()
config_data.set_quoted('EXEC_NAME', meson.project_name())
config_data.set_quoted('NAME', 'Pachy')
config_data.set_quoted('DOMAIN', meson.project_name())
config_data.set_quoted('G_LOG_DOMAIN', 'Pachy')
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_data.set_quoted('VERSION', meson.project_version())
config_data.set_quoted('WEBSITE', 'https://github.com/leggettc18/pachy')
config_data.set_quoted('SUPPORT_WEBSITE', 'https://github.com/leggettc18/pachy/issues')
config_data.set_quoted('PROFILE', devel ? 'development' : 'production')

if devel
    git = find_program('git')
    if git.found()
        branch = run_command('git', 'branch', '--show-current', check: true).stdout().strip()
        revision = run_command('git', 'rev-parse', '--short', 'HEAD', check: true).stdout().strip()
        version = '@0@-@1@'.format(branch, revision)
        config_data.set_quoted('VERSION', version)
    endif
endif

config_file = configure_file(
    output: 'config.h',
    configuration: config_data
)

granite_dep = dependency('granite-7')
gtk_dep = dependency('gtk4')
webkit_dep = dependency('webkitgtk-6.0')
json_dep = dependency('json-glib-1.0')

dependencies = [
    granite_dep,
    gtk_dep,
    webkit_dep,
    json_dep,
]

gnome.post_install(glib_compile_schemas: true)

sources = files(
    'vapi/build.vapi',
)

subdir('data')
subdir('po')
subdir('src')

executable(
    meson.project_name(),
    gresource,
    sources,
    config_file,
    dependencies: dependencies,
    install: true
)
