local logger = require('lib.logger')
local user = require('lib.user')

local env = { }

local file, err = io.open(
	string.format(
		'%s/.env',
		user.get_value('config_dir')),
	'r')

if file == nil then
	logger.log('[dot_env] %s', err)
	return env
end

for key, value in string.gmatch(file:read('a'), '(%w+)=(%w+)') do
	env[key] = value
end

file:close()

return env
