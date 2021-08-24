fx_version 'bodacious'
game 'gta5'

ui_page('web/impound/index-en.html')
-- ui_page('web/impound/index-es.html')
-- ui_page('web/impound/index-fr.html')

files {
    'web/impound/img/*',
    'web/impound/index-en.html',
    'web/impound/script-en.js',
    'web/impound/style-en.css'
    -- 'web/impound/index-es.html',
    -- 'web/impound/script-es.js',
    -- 'web/impound/style-es.css'
    -- 'web/impound/index-fr.html',
    -- 'web/impound/script-fr.js',
    -- 'web/impound/style-fr.css'
}

shared_scripts {
}

client_scripts {
	'@PolyZone/client.lua',
	--## Language Files
	'@es_extended/locale.lua',
	'locales/en.lua',
	--  'locales/es.lua',
	'locales/fr.lua',
	--## ESX Utils
	'client/_utils.lua',
	--## Config Files
	'config.lua',
	'config/parkings.lua',
	'config/warehouses.lua',
	'config/recoverpoints.lua',
	'config/garages.lua',
	--## Core Files
	'client/carstatus.lua',
	'client/impound.lua',
	'client/personalmenu.lua',
	'client/garages.lua',
	'client/recover.lua',
	'client/main.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server/mock.lua',
	--## Language Files
	'@es_extended/locale.lua',
	--  'locales/es.lua',
	'locales/fr.lua',
	'locales/en.lua',
	--## ESX Utils
	'server/_utils.lua',
	--## Config Files
	'config.lua',
	'config/parkings.lua',
	'config/warehouses.lua',
	'config/recoverpoints.lua',
	'config/garages.lua',
	--## Core Files
	'server/impound.lua',
	'server/personalmenu.lua',
	'server/garages.lua',
	'server/recover.lua',
	'server/main.lua',
}

exports {
    "AddCarOnEarth",
    "IsCarOnEarth",
    "RemoveCarFromEarth"
 }