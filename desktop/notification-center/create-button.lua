local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local icons = require('config.theme.icons')
local widgets = require('widgets')

local margins = beautiful.margins

local create_button = function (s)

	local icon = wibox.widget {
		image = icons.info_center,
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

	button:buttons(awful.button(
		{ },
		1,
		nil,
		function ()
			awesome.emit_signal('desktop::notification-center', nil, s)
		end))

	return button
end

return create_button
