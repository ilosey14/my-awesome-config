local awful = require('awful')
local mod = require('config.global.mod')

local super = mod.super

return awful.util.table.join(
	awful.button(
		{ },
		awful.button.names.LEFT,
		function (c)
			if not c.active then c:activate() end
		end
	),
	awful.button(
		{ },
		awful.button.names.MIDDLE,
		function (c)
			if not c.active then c:activate() end
		end
	),
	awful.button(
		{ },
		awful.button.names.RIGHT,
		function (c)
			if not c.active then c:activate() end
		end
	),

	awful.button(
		{ super },
		awful.button.names.LEFT,
		function (c)
			if not c.active then c:activate() end
			if c.maximized then c.maximized = false end

			awful.mouse.client.move(c)
		end
	),
	awful.button(
		{ super },
		awful.button.names.RIGHT,
		function (c)
			if not c.active then c:activate() end

			awful.mouse.client.resize(c)
		end
	)
)