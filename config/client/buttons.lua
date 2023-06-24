local awful = require('awful')

local config = require('lib.config')
local mod = require('config.global.mod')

local settings = config.load('config.client.settings')
local super = mod.super

awful.mouse.drag_to_tag.enabled = settings.drag_to_tag_enabled
awful.mouse.resize.set_mode(settings.resize_mode)
awful.mouse.snap.aerosnap_distance = settings.snap_aerosnap_distance
awful.mouse.snap.default_distance = settings.snap_default_distance
awful.mouse.snap.edge_enabled = settings.snap_edge_enabled

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
			if c.maximized_vertical then c.maximized_vertical = false end
			if c.maximized_horizontal then c.maximized_horizontal = false end

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