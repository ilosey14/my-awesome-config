local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local icons = require('config.theme.icons')
local widgets = require('widgets')

local is_open = false
local margins = beautiful.margins

local function create_button()
	local icon = wibox.widget {
		image = icons.systray_toggle_closed,
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
		1,
		nil,
		function ()
			is_open = not is_open

			awesome.emit_signal('desktop::systray', is_open)

			if is_open then
				icon:set_image(icons.systray_toggle_open)
			else
				icon:set_image(icons.systray_toggle_closed)
			end
		end
	))

	return button
end

return create_button
