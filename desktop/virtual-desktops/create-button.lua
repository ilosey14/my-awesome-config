local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local icons = require('config.theme.icons')
local widgets = require('widgets')

local margins = beautiful.margins

local function create_button()
	local icon = wibox.widget {
		image = icons.virtual_desktop,
		stylesheet = beautiful.icon_stylesheet,
		resize = true,
		widget = wibox.widget.imagebox
	}

	local button = wibox.widget {
		{
			icon,
			margins = margins,
			widget = wibox.container.margin
		},
		widget = widgets.clickable
	}

	button:add_button(awful.button(
		{ },
		awful.button.names.LEFT,
		nil,
		function ()
			awesome.emit_signal('desktop::virtual-desktop')
		end)
	)

	return button
end

--

return create_button
