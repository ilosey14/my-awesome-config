local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local grabber
local default_text = 'Press [Escape] to exit...'
local input_display = wibox.widget {
	text = default_text,
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}
local popup = awful.popup {
	widget = {
		{
			layout = wibox.layout.fixed.vertical,
			spacing = beautiful.spacing,
			{
				text = 'Input Inspector',
				font = beautiful.font_bold,
				align = 'center',
				valign = 'center',
				widget = wibox.widget.textbox
			},
			input_display
		},
		margins = beautiful.margins,
		widget = wibox.container.margin
	},
	screen = screen.primary,
	placement = awful.placement.centered,
	ontop = true,
	visible = false,
	bg = beautiful.primary,
	shape = beautiful.shapes.rounded_rect
}

local function stop_inspector()
	popup.visible = false
	input_display.text = default_text
	grabber:stop()
	grabber = nil
end

local function start_inspector()
	popup.visible = true
	grabber = awful.keygrabber {
		keypressed_callback = function (self, mod, key)
			local mods = #mod and table.concat(mod, '+')..'+' or ''
			input_display.text = mods..key
		end,
		stop_key = 'Escape',
		stop_callback = stop_inspector,
		autostart = true
	}
end

--

awesome.connect_signal(
	'utils::input-inspector',
	function (run)
		if type(run) ~= 'boolean' then
			run = not awful.keygrabber.is_running
		end

		if run then
			start_inspector()
		else
			stop_inspector()
		end
	end)
