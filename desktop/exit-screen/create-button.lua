local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local icons = require('config.theme.icons')
local widgets = require('widgets')

local function create_button()
	local button = wibox.widget {
		{
			{
				image = icons.power,
				stylesheet = beautiful.icon_stylesheet,
				resize = true,
				widget = wibox.widget.imagebox
			},
			widget = widgets.clickable
		},
		bg = beautiful.transparent,
		shape = beautiful.shapes.circle,
		widget = wibox.container.background
	}

	button:buttons {
		awful.button(
			{ },
			awful.button.names.LEFT,
			nil,
			function () awesome.emit_signal('desktop::exit-screen') end)
	}

	return button
end

--
return create_button
