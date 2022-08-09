local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local apps = require('config.apps')
local icons = require('config.theme.icons')
local widgets = require('widgets')

local gap = beautiful.useless_gap

local create_button = function ()
	local app_drawer = wibox.widget {
		{
			{
				image = icons.app_drawer,
				-- stylesheet = beautiful.icon_stylesheet,
				resize = true,
				widget = wibox.widget.imagebox
			},
			buttons = {
				awful.button {
					modifiers = { },
					button = awful.button.names.LEFT,
					on_press = function () awful.spawn(apps.default.appmenu, false) end
				}
			},
			margins = gap,
			widget = wibox.container.margin
		},
		widget = widgets.clickable
	}

	return app_drawer
end

return create_button
