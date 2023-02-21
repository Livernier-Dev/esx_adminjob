-- NC PROTECT+
server_scripts { '@nc_PROTECT+/exports/sv.lua' }
client_scripts { '@nc_PROTECT+/exports/cl.lua' }

--[[
 	resource: LVR Dev
	discord: https://discord.gg/9RpKaQN7JJ
	หากมีปัญหาทักมาสอบถามได้เลยครับ
--]]
fx_version 'adamant'
game 'gta5'


description 'ESX admin Job'

version '1.3.0'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
	'locales/en.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'@es_extended/locale.lua',
	'locales/en.lua',
	'config.lua',
	'client/main.lua'
}

dependencies {
	'es_extended',
}