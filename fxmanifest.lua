fx_version 'adamant'
games { 'gta5' }

client_scripts {
    "client/fxserver_c_events.lua"
}

server_scripts {
    "@vrp/lib/utils.lua",
    '@mysql-async/lib/MySQL.lua',

    'server/fxserver_events.lua',
    'main_controller.js',
}

ui_page "web/index.html"

files {
	"web/assets/*",
    "web/*"
}