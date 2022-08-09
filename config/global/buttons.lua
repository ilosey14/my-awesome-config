local awful = require('awful')

local apps = require('config.apps')

local buttons = {
	awful.button(
		{ },
		awful.button.names.LEFT,
		function ()
			awesome.emit_signal('desktop::menu', false)

			-- TODO unfocus client
			--[=[ local c = client.focus

			if c then --[[ unfocus somehow... ]] end ]=]
		end),
	awful.button(
		{ },
		awful.button.names.RIGHT,
		function () awesome.emit_signal('desktop::menu') end),
	awful.button(
		{ },
		awful.button.names.MIDDLE,
		function () awful.spawn(apps.default.appmenu) end)
}

root.buttons(buttons)
