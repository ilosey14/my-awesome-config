local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local icons = require('config.theme.icons')
local widgets = require('widgets')

local margins = beautiful.margins

local create_button = function ()

	local widget = wibox.widget {
		{
			id = 'icon',
			image = icons.search,
			stylesheet = beautiful.icon_stylesheet,
			resize = true,
			widget = wibox.widget.imagebox
		},
		layout = wibox.layout.align.horizontal
	}

	local widget_button = wibox.widget {
		{
			widget,
			margins = margins,
			widget = wibox.container.margin
		},
		widget = widgets.clickable
	}

	widget_button:buttons {
		awful.button {
			modifiers = { },
			button = awful.button.names.LEFT,
			on_press = function () awesome.emit_signal('desktop::search') end
		}
	}

	return widget_button
end

return create_button
