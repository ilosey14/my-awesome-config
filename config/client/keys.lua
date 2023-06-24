local awful = require('awful')
local beautiful = require('beautiful')

local keys = require('config.global.mod')

local margins = beautiful.margins
local super = keys.super
local alt = keys.alt
local shift = keys.shift
local ctrl = keys.ctrl

local snap_to_left =
	awful.placement.scale +
	awful.placement.maximize_vertically +
	awful.placement.left
local snap_to_right =
	awful.placement.scale +
	awful.placement.maximize_vertically +
	awful.placement.right

local client_keys = awful.util.table.join(
	awful.key(
		{ },
		'F11',
		function (c)
			c.fullscreen = not c.fullscreen
			c:raise()
		end,
		{ description = 'Toggle fullscreen', group = 'Client' }
	),
	awful.key(
		{ super },
		'q',
		function (c) c:kill() end,
		{ description = 'Close', group = 'Client' }
	),
	awful.key(
		{ super },
		'Tab',
		function () awful.client.swap.byidx(1) end,
		{ description = 'Swap with next window tile', group = 'Client' }
	),
	awful.key(
		{ super, shift },
		'Tab',
		function ()
			awful.client.swap.byidx(-1)
		end,
		{ description = 'Swap with previous window tile', group = 'Client' }
	),
	awful.key(
		{ super },
		'g',
		awful.client.urgent.jumpto,
		{ description = 'Go to urgent window', group = 'Client' }
	),
	awful.key(
		{ super },
		'c',
		function (c)
			-- local focused = awful.screen.focused()

			awful.placement.centered(c, { honor_workarea = true })
		end,
		{ description = 'Align window to center of focused screen', group = 'Client' }
	),
	awful.key(
		{ super },
		'f',
		function (c)
			c.fullscreen = false
			c.maximized = false
			c.floating = not c.floating
			c:raise()
		end,
		{ description = 'Toggle floating', group = 'Client' }
	),
	awful.key(
		{ super },
		't',
		function (c) c.ontop = not c.ontop end,
		{ description = 'Toggle always on top', group = 'Client' }
	),
	awful.key(
		{ super, ctrl },
		't',
		function (c) client.emit_signal('titlebar:visible', c) end,
		{ description = 'Toggle titlebar visibility', group = 'Client' }
	),
	awful.key(
		{ super },
		'm',
		function (c) c.maximized = not c.maximized end,
		{ description = 'Maximize the window (toggle)', group = 'Client' }
	),
	awful.key(
		{ super },
		'n',
		function (c) c.minimized = true end,
		{ description = 'Minimize window', group = 'Client' }
	),
	awful.key(
		{ super },
		'Up',
		function (c) c.maximized = true end,
		{ description = 'Maximize the window', group = 'Client' }
	),
	awful.key(
		{ super },
		'Down',
		function (c)
			if c.maximized then
				c.maximized = false
			elseif c.maximized_vertical then
				c.maximized_vertical = false
			else
				c.minimized = true
			end
		end,
		{ description = 'Minimize or restore the window', group = 'Client' }
	),

	awful.key(
		{ super, shift },
		'Up',
		function (c) c.maximized_vertical = true end,
		{ description = 'Toggle vertically maximizing the window', group = 'Client' }
	),
	awful.key(
		{ super, shift },
		'Down',
		function (c) c.maximized_vertical = false end,
		{ description = 'Restore vertically maximized window', group = 'Client'}
	),
	-- edge snapping
	-- https://awesomewm.org/apidoc/libraries/awful.placement.html
	awful.key(
		{ super },
		'Left',
		function (c)
			c.maximized_vertical = true
			snap_to_left(c, { honor_workarea = true, margins = margins, to_percent = 0.5 })
		end,
		{ description = 'Snap to left', group = 'Client' }
	),
	awful.key(
		{ super },
		'Right',
		function (c)
			c.maximized_vertical = true
			snap_to_right(c, { honor_workarea = true, margins = margins, to_percent = 0.5 })
		end,
		{ description = 'Snap to right', group = 'Client' }
	),
	--
	awful.key(
		{ super, shift },
		'Left',
		function (c) c:move_to_screen(c.screen.index - 1) end,
		{ description = 'Move to previous screen', group = 'Client' }
	),
	awful.key(
		{ super, shift },
		'Right',
		function (c) c:move_to_screen(c.screen.index + 1) end,
		{ description = 'Move to next screen', group = 'Client' }
	)
)

return client_keys
