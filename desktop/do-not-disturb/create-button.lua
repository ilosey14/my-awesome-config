local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local icons = require('config.theme.icons')
local widgets = require('widgets')

local background_off = beautiful.groups_bg
local background_on = beautiful.accent
local margins = beautiful.margins

local tooltip = awful.tooltip {
	text = 'Do Not Disturb',
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
					image = icons.do_not_disturb,
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
			function () awesome.emit_signal('desktop::do-not-disturb') end)
	}

	tooltip:add_to_object(button)

	-- signals

	awesome.connect_signal(
		'desktop::do-not-disturb:event',
		function (state)
			-- toggle background
			button.bg = state and background_on or background_off
		end)

	-- initial state

	awesome.emit_signal(
		'desktop::do-not-disturb:get',
		function (state)
			button.bg = state and background_on or background_off
		end)

	return button
end

--
return create_button
