local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local icons = require('config.theme.icons')
local widgets = require('widgets')

local background_off = beautiful.groups_bg
local background_on = beautiful.accent
local margins = beautiful.margins

local tooltip = awful.tooltip {
	text = 'Bluetooth',
	delay_show = 1,
	preferred_positions = { 'bottom', 'top', 'left', 'right' },
	preferred_alignments = { 'middle', 'front', 'back' },
	margins = margins,
	shape = beautiful.shapes.rounded_rect
}

local function create_button()
	local button = wibox.widget {
		{
			{
				{
					image = icons.bluetooth,
					stylesheet = beautiful.icon_stylesheet,
					resize = true,
					widget = wibox.widget.imagebox
				},
				margins = margins,
				widget = wibox.container.margin
			},
			widget = widgets.clickable
		},
		bg = background_off,
		shape = beautiful.shapes.circle,
		widget = wibox.container.background
	}

	button:buttons {
		awful.button(
			{ },
			awful.button.names.LEFT,
			nil,
			function () awesome.emit_signal('desktop::bluetooth') end)
	}

	tooltip:add_to_object(button)

	-- signals

	awesome.connect_signal(
		'desktop::bluetooth:event',
		function (is_on)
			-- disable button
			if not is_on then
				button.opacity = 0.5
				return
			end

			-- toggle background
			button.bg = is_on and background_on or background_off
		end)

	-- initial state

	awesome.emit_signal(
		'desktop::bluetooth:get',
		function (state) button.bg = state and background_on or background_off end)

	return button
end

--
return create_button
