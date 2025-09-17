fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'F4R3'
description 'Sistema de misiones con NPCs interactivos o robables'
version '0.1.0'

-- Página principal de la interfaz
ui_page 'html/index.html'

-- Archivos que usará la NUI
files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

-- Librerías y scripts
shared_script '@ox_lib/init.lua'

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server.lua',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'qbx_core'
}
