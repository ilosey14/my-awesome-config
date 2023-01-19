local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local config = require('lib.config')
local icons = require('config.theme.icons')
local widgets = require('widgets')

local dpi = beautiful.xresources.apply_dpi
local settings = config.load('desktop.calendar.settings', { beautiful = beautiful })

local styles = settings.styles

local button_size = beautiful.taskbar_height
local foreground = beautiful.fg_normal
local margins = beautiful.margins
local spacing = beautiful.spacing
local transparent = beautiful.transparent

--

local function get_today()
	return os.date('*t')
end

local current_date = get_today()

local function style_calendar(widget, flag, date)
	local props = styles[flag] or { }

	return wibox.widget {
		{
			widget,
			margins = props.margins or margins,
			widget = wibox.container.margin
		},
		border_color = props.border_color or transparent,
		border_width = props.border_width or 0,
		fg = props.fg_color or foreground,
		bg = props.bg_color or transparent,
		shape = props.shape,
		widget = wibox.container.background
	}
end

local back_button = wibox.widget {
	{
		{
			image = icons.back,
			stylesheet = beautiful.icon_stylesheet,
			resize = true,
			forced_height = button_size,
			forced_width = button_size,
			widget = wibox.widget.imagebox
		},
		margins = margins,
		widget = wibox.container.margin
	},
	widget = widgets.clickable
}

local today_button = wibox.widget {
	{
		wibox.widget.textbox('Today'),
		margins = margins,
		widget = wibox.container.margin
	},
	widget = widgets.clickable
}

local forward_button = wibox.widget {
	{
		{
			image = icons.forward,
			stylesheet = beautiful.icon_stylesheet,
			resize = true,
			forced_height = button_size,
			forced_width = button_size,
			widget = wibox.widget.imagebox
		},
		margins = margins,
		widget = wibox.container.margin
	},
	widget = widgets.clickable
}

local function create_calendar(date)
	return wibox.widget {
		date = date or get_today(),
		spacing = spacing,
		start_sunday = true,
		long_weekdays = true,
		fn_embed = style_calendar,
		widget = wibox.widget.calendar.month
	}
end

local panel = awful.popup {
	widget = {
		{
			{
				back_button,
				{
					nil,
					today_button,
					nil,
					expand = 'outside',
					layout = wibox.layout.align.horizontal
				},
				forward_button,
				layout = wibox.layout.align.horizontal
			},
			margins = margins,
			widget = wibox.container.margin
		},
		create_calendar(),
		layout = wibox.layout.fixed.vertical
	},
	type = 'popup_menu',
	visible = false,
	ontop = true,
	width = 1, -- forces initial placement
	bg = beautiful.background,
	shape = beautiful.rounded_rect
}

local function set_calendar(date)
	local calendar = create_calendar(date)

	current_date = date
	panel.widget:set(2, calendar)
end

local function set_today()
	set_calendar(get_today())
end

local function dec_month()
	local date = current_date
	local month = date.month

	if month <= 1 then
		date.year = date.year - 1
		date.month = 12
	else
		date.month = month - 1
	end

	set_calendar(date)
end

local function inc_month()
	local date = current_date
	local month = date.month

	if month >= 12 then
		date.year = date.year + 1
		date.month = 1
	else
		date.month = month + 1
	end

	set_calendar(date)
end

back_button:add_button(
	awful.button(
		{ },
		awful.button.names.LEFT,
		nil,
		function () dec_month() end))

today_button:add_button(
	awful.button(
		{ },
		awful.button.names.LEFT,
		nil,
		function () set_today() end))

forward_button:add_button(
	awful.button(
		{ },
		awful.button.names.LEFT,
		nil,
		function () inc_month() end))

local function show_calendar(s)
	if panel.visible then return end

	panel.screen = s or screen.primary
	panel.maximum_width = s.geometry.width

	awful.placement.top_right(
		panel,
		{
			honor_workarea = true,
			parent = s,
			margins = {
				top = dpi(44),
				right = margins
			}
		})

	awesome.emit_signal('desktop::mask:visible', true, s)
	panel.visible = true
end

local function hide_calendar(s)
	if not panel.visible then return end
	if s and panel.s ~= s then return end

	awesome.emit_signal('desktop::mask:visible', false)

	panel.visible = false
end

-- signals

awesome.connect_signal(
	'desktop::calendar',
	function (s, is_visible)
		if type(is_visible) ~= 'boolean' then
			is_visible = not panel.visible
		end

		if is_visible then
			show_calendar(s)
		else
			hide_calendar(s)
		end
	end)

awesome.connect_signal(
	'desktop::mask:dismissed',
	function () hide_calendar() end)

--

return {
	-- create_button = require('desktop.calendar.create_button')
}
