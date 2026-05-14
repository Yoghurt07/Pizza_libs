fx_version 'adamant'
game 'gta5'
lua54 'yes'

author 'Yoghurt'
description 'Shared FiveM library (NUI, notify, progressbar, …) for any resource — use like st_libs.'
version '1.0.0'

ui_page 'web/build/index.html'

files {
    'init.lua',
    'modules/**.lua',
    'web/build/index.html',
    'web/build/assets/**/*.png',
    'web/build/assets/**/*',
    'web/build/**/*',
    'locales/*.json',
}

shared_scripts {
    'resource/init.lua',
    'resource/**/shared.lua',
}

client_scripts {
    'resource/client/nui_bridge.lua',
    'resource/**/client.lua',
}

server_scripts {
    'resource/**/server.lua',
}
