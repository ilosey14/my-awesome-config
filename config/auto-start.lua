local awful = require('awful')
local naughty = require('naughty')

local config = require('lib.config')

local apps = require('config.apps')
local settings = config.load('config.settings')

local debug_mode = settings.debug_mode
local startup = apps.startup
local shutdown = apps.shutdown

local run_once = function (cmd)
	local find_me = cmd
	local first_space = string.find(cmd, ' ')

	if first_space then
		find_me = string.sub(cmd, 0, first_space - 1)
	end

	awful.spawn.easy_async_with_shell(
		string.format('pgrep -u $USER -x %s > /dev/null || (%s)', find_me, cmd),
		function (stdout, stderr)
			if not stderr or stderr == '' or not debug_mode then
				return
			end

			naughty.notification {
				app_name = 'Start-up Applications',
				title = '<b>Oof! Error detected when starting an application!</b>',
				message = string.gsub(stderr, '%\n', ''),
				timeout = 20,
				icon = require('beautiful').awesome_icon
			}
		end)
end

for _, app in ipairs(startup) do
	run_once(app)
end

-- register shutdown commands
awesome.connect_signal('exit', function (restart)
	-- ignore restarts
	if restart then return end

	for _, script in ipairs(shutdown) do
		awful.spawn.easy_async_with_shell(script, function () end)
	end
end)
