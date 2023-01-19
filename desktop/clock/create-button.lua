local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local config = require('lib.config')
local widgets = require('widgets')

local settings = config.load('desktop.clock.settings')

local military_clock = settings.military_clock
local margins = beautiful.margins

--

local function create_button(s)
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

	button:buttons(awful.button(
		{ },
		1,
		nil,
		function () awesome.emit_signal('desktop::calendar', s) end))

	--
	return button
end

return create_button
