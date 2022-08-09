local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local apps = require('config.apps')
local icons = require('config.theme.icons')
local widgets = require('widgets')

local margins = beautiful.margins

local function create_button()
	local icon = wibox.widget {
		image = icons.battery,
		stylesheet = beautiful.icon_stylesheet,
		widget = wibox.widget.imagebox,
		resize = true
	}

	local percentage_label = wibox.widget {
		text = '',
		font = 'Roboto Bold 11',
		align = 'center',
		valign = 'center',
		widget = wibox.widget.textbox
	}

	local widget = wibox.widget {
		layout = wibox.layout.fixed.horizontal,
		spacing = 0,
		icon,
		percentage_label
	}

	local button = wibox.widget {
		{
			widget,
			margins = margins,
			widget = wibox.container.margin
		},
		visible = false,
		widget = widgets.clickable
	}

	button:add_button(
		awful.button(
			{ },
			awful.button.names.LEFT,
			nil,
			function () awful.spawn(apps.default.power_manager, false) end
		))

	-- connect signals
	awesome.connect_signal(
		'desktop::battery:visible',
		function (is_visible)
			if type(is_visible) == 'boolean' then
				button.visible = is_visible
			else
				button.visible = not button.visible
			end
		end)

	awesome.connect_signal(
		'desktop::battery',
		function (battery)
			icon.image = icons[battery.icon_name] or icons.battery
			percentage_label.text = battery.percentage
		end)

	return button
end

return create_button
