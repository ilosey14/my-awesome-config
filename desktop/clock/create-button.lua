local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')
local wibox = require('wibox')

local config = require('lib.config')
local user = require('lib.user')
local widgets = require('widgets')

local dpi = beautiful.xresources.apply_dpi
local margins = beautiful.margins
local settings = config.load('config.settings', { config_dir = user.get_value('config_dir') })
local spacing = beautiful.spacing

-- const
local military_clock = settings.military_clock

--

local create_button = function (s)
	local clock_format = string.format(
		'<b>%%a, %%b %%d  |  %s</b>',
		(military_clock and '%H:%M') or '%I:%M %p')

	local button = wibox.widget {
		{
			wibox.widget.textclock(clock_format, 1),
			margins = margins,
			widget = wibox.container.margin
		},
		widget = widgets.clickable
	}

	local calendar = awful.widget.calendar_popup.month({
		start_sunday = true,
		spacing = spacing,
		font = beautiful.font,
		long_weekdays = true,
		margin = dpi(4),
		screen = s,
		style_month = {
			border_width	= dpi(0),
			bg_color = beautiful.background,
			padding = dpi(16),
			shape = function (cr, width, height)
				gears.shape.rounded_rect(cr, width, height, beautiful.groups_radius)
			end
		},
		style_header = {
			border_width	= 0,
			bg_color = beautiful.transparent
		},
		style_weekday = {
			border_width	= 0,
			bg_color = beautiful.transparent
		},
		style_normal = {
			border_width	= 0,
			bg_color = beautiful.transparent
		},
		style_focus = {
			border_width	= dpi(0),
			border_color	= beautiful.fg_normal,
			bg_color = beautiful.accent,
			shape = function (cr, width, height)
				gears.shape.rounded_rect(cr, width, height, dpi(4))
			end,
		},
	})

	calendar:attach(
		button,
		'tr',
		{
			on_pressed = true,
			on_hover = false
		}
	)

	return button
end

return create_button
