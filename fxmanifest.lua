fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'piercer_clothslot'
author 'piercer'
description 'Identificador de slots, pastas e inspetor de roupas em tempo real'
version '2.0.0'

ui_page 'web/index.html'

shared_scripts {
	'config.lua',
	'@framezero_bridge/import.lua'
}

client_scripts {
	'@vrp/lib/utils.lua',
	'client/main.lua'
}

server_scripts {
	'@vrp/lib/utils.lua',
	'server/main.lua'
}

files {
	'web/index.html',
	'web/style.css',
	'web/app.js',
	'data/index.lua'
}
