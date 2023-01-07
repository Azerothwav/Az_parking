fx_version 'bodacious'
game 'gta5'
lua54        'yes'

shared_scripts {
	'config.lua'
}

client_scripts {
	"lib/RMenu.lua",
    "lib/menu/RageUI.lua",
    "lib/menu/Menu.lua",
    "lib/menu/MenuController.lua",
    "lib/components/*.lua",
    "lib/menu/elements/*.lua",
    "lib/menu/items/*.lua",
    "lib/menu/panels/*.lua",
    "lib/menu/panels/*.lua",
    "lib/menu/windows/*.lua",

    'init.lua',
    'data/*.json',
	'client/*.lua',
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server/*.lua',
}

exports {
    "AddCarOnEarth",
    "IsCarOnEarth",
    "RemoveCarFromEarth"
}

dependencies {
	'Az_context'
}