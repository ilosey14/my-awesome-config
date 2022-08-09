local config = require('lib.config')
local user = require('lib.user')

local config_dir = user.get_value('config_dir')

return {
	default = config.load(
		'config.apps.default',
		{
			screen = screen,
			config_dir = config_dir
		}),
	pinned = config.load('config.apps.pinned'),
	startup = config.load('config.apps.startup', { config_dir = config_dir }),
	shutdown = config.load('config.apps.shutdown', { config_dir = config_dir })
}
