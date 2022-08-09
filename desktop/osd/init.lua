local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local timers = require('lib.timers')

local dpi = beautiful.xresources.apply_dpi
local margins = beautiful.margins
local osd_height = dpi(256)
local osd_width = dpi(256)
local spacing = beautiful.spacing

--

local icon = wibox.widget {
	stylesheet = beautiful.icon_stylesheet,
	resize = true,
	widget = wibox.widget.imagebox
}

local label = wibox.widget {
	text = '',
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local value = wibox.widget {
	text = '',
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local slider = wibox.widget {
	bar_shape = beautiful.shapes.rounded_rect,
	bar_height = dpi(16),
	bar_color = beautiful.secondary,
	handle_shape = beautiful.shapes.circle,
	handle_color = beautiful.accent,
	handle_border_color = beautiful.primary,
	handle_border_width = dpi(1),
	minimum = 0,
	maximum = 100,
	widget = wibox.widget.slider
}

local widget = wibox.widget {
	{
		{
			layout = wibox.layout.fixed.vertical,
			spacing = spacing,
			{
				layout = wibox.layout.align.horizontal,
				expand = 'none',
				nil,
				{
					icon,
					forced_height = osd_height / 2,
					margins = margins,
					widget = wibox.container.margin
				},
				nil
			},
			{
				layout = wibox.layout.fixed.vertical,
				spacing = spacing,
				{
					layout = wibox.layout.align.horizontal,
					expand = 'none',
					label,
					nil,
					value
				},
				{
					layout = wibox.layout.align.vertical,
					expand = 'none',
					nil,
					slider,
					nil
				}
			}
		},
		margins = margins,
		widget = wibox.container.margin
	},
	bg = beautiful.bg_normal,
	shape = beautiful.shapes.rounded_rect,
	widget = wibox.container.background
}

local popup = awful.popup {
	widget = widget,
	ontop = true,
	visible = false,
	type = 'notification',
	height = osd_height,
	width = osd_width,
	maximum_height = osd_height,
	maximum_width = osd_width,
	shape = beautiful.shapes.rectangle,
	bg = beautiful.transparent,
	preferred_anchors = 'middle',
	preferred_positions = 'top',
	offset = { x = 0, y = -dpi(16) },
	geometry = awful.screen.focused,
	placement = awful.placement.bottom
}

-- functions

local hide_osd = timers.debounce(
	function () popup.visible = false end,
	2)

local function show_osd(s)
	if not popup.visible then
		popup.screen = s or awful.screen.focused()
		popup.visible = true
	end

	hide_osd()
end

-- signals

awesome.connect_signal(
	'desktop::osd',
	function (args)
		if not args then args = { } end

		-- set values
		icon.image = args.icon
		label.text = args.label
		value.text = string.format('%.f%%', args.value)
		slider.value = args.value

		-- show popup
		show_osd()
	end)
