local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')
local naughty = require('naughty')
local wibox = require('wibox')

local config = require('lib.config')
local date = require('lib.date')
local logger = require('lib.logger')
local timers = require('lib.timers')
local user = require('lib.user')

if not package.loaded['liblua_pam'] then
	logger.error('Loading lock screen refused: authentication package "liblua_pam" not found.')
	return
end

local dpi = beautiful.xresources.apply_dpi
local desktop_settings = config.load('config.settings', { config_dir = user.get_value('config_dir') })
local lockscreen_settings = config.load('desktop.lock-screen.settings')

-- const
local wallpaper = beautiful.lockscreen_wallpaper
local military_clock = desktop_settings.military_clock
local unlock_delay = lockscreen_settings.unlock_delay

-- state
local input_password = ''
local is_visible = false

--

local user_text = wibox.widget {
	text = user.format('%{name} @ %{host}'),
	font = 'Roboto Bold 12',
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local caps_text = wibox.widget {
	text = 'Caps Lock is on',
	font = 'Roboto Italic 10',
	align = 'center',
	valign = 'center',
	opacity = 0,
	widget = wibox.widget.textbox
}

local user_image = wibox.widget {
	image = user.get_value('image'),
	resize = true,
	forced_height = dpi(130),
	forced_width = dpi(130),
	clip_shape = beautiful.shapes.circle,
	widget = wibox.widget.imagebox
}

-- clock widget

local time_text = wibox.widget.textclock(
	string.format(
		'<span font="Roboto Bold 52">%s</span>',
		(military_clock and '%H:%M') or '%I:%M %p'),
	1)

local date_text = wibox.widget {
	text = date.tolocalestring(),
	font = 'Roboto Bold 20',
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

-- input animation

local locker_container = wibox.widget {
	bg = beautiful.transparent,
	forced_width = dpi(140),
	forced_height = dpi(140),
	shape = beautiful.shapes.circle,
	widget = wibox.container.background
}

local locker_arc = wibox.widget {
	bg = beautiful.transparent,
	forced_width = dpi(140),
	forced_height = dpi(140),
	shape = function (cr, width, height)
		gears.shape.arc(cr, width, height, dpi(5), 0, (math.pi / 2), false, false)
	end,
	widget = wibox.container.background
}

local rotate_container = wibox.container.rotate()
local rotation_direction = { 'north', 'east', 'south', 'west' }

local locker_widget = wibox.widget {
	{
		locker_arc,
		widget = rotate_container
	},
	layout = wibox.layout.fixed.vertical
}

-- colors

local red = string.format('%sAA', beautiful.red)
local green = string.format('%sAA', beautiful.green)
local yellow = string.format('%sAA', beautiful.yellow)
local blue = string.format('%sAA', beautiful.blue)

local arc_color = { red, green, yellow, blue }

-- functions

local function reset_lockscreen()
	input_password = ''
	locker_container.bg = beautiful.transparent
end

local function login_success()
	locker_container.bg = green

	timers.set_timeout(
		function ()
			awesome.emit_signal('desktop::lock-screen', false)
			reset_lockscreen()
		end,
		unlock_delay)
end

local function login_fail()
	locker_container.bg = red

	timers.set_timeout(reset_lockscreen, 0.5)
end

local function login_reset()
	locker_container.bg = blue

	timers.set_timeout(reset_lockscreen, 1)
end

local function check_caps_state()
	awful.spawn.easy_async_with_shell(
		'xset q | grep -Po "Caps Lock:\\s+\\w+" | cut -d: -f2 | xargs',
		function (stdout)
			if stdout:match('on') then
				caps_text.opacity = 1
			else
				caps_text.opacity = 0
			end

			-- caps_text:emit_signal('widget::redraw_needed')
		end)
end

local function locker_arc_rotate()
	local direction = rotation_direction[math.random(#rotation_direction)]
	local color = arc_color[math.random(#arc_color)]

	rotate_container.direction = direction
	locker_arc.bg = color

	-- rotate_container:emit_signal('widget::redraw_needed')
	-- locker_arc:emit_signal('widget::redraw_needed')
	-- locker_widget:emit_signal('widget::redraw_needed')
end

-- input grabber

local password_grabber = awful.keygrabber {
	stop_event = 'release',
	mask_event_callback = true,
	keypressed_callback = function (self, mod, key, command)
		-- reset login flow
		if key == 'Escape' then
			login_reset()
			return
		end

		-- only append single characters
		if #key == 1 then
			locker_arc_rotate()
			input_password = input_password .. key
		end
	end,
	keyreleased_callback = function (self, mod, key, command)
		locker_container.bg = beautiful.transparent
		locker_arc.bg = beautiful.transparent
		locker_arc:emit_signal('widget::redraw_needed')

		if key == 'Caps_Lock' then
			check_caps_state()
			return
		end

		if key == 'Return' then
			-- show progress
			locker_container.bg = blue
			locker_container:emit_signal('widget::redraw_needed')

			-- authenticate
			local authenticated = false

			if #input_password > 0 then
				authenticated = user.authenticate(input_password)
			end

			if authenticated then
				login_success()
			else
				login_fail()
			end
		end
	end
}

-- create lock screen

local function create_main_lockscreen(s)
	local lockscreen = wibox {
		screen = s,
		visible = false,
		ontop = true,
		type = 'splash',
		width = s.geometry.width,
		height = s.geometry.height,
		fg = beautiful.fg_normal,
		bg = beautiful.background
	}

	lockscreen:setup {
		{
			image = wallpaper,
			resize = true,
			horizontal_fit_policy = 'fit',
			vertical_fit_policy = 'fit',
			widget = wibox.widget.imagebox
		},
		{
			layout = wibox.layout.align.vertical,
			expand = 'none',
			nil,
			{
				layout = wibox.layout.align.horizontal,
				expand = 'none',
				nil,
				{
					layout = wibox.layout.fixed.vertical,
					expand = 'none',
					spacing = dpi(20),
					{
						{
							layout = wibox.layout.align.horizontal,
							expand = 'none',
							nil,
							time_text,
							nil
						},
						{
							layout = wibox.layout.align.horizontal,
							expand = 'none',
							nil,
							date_text,
							nil
						},
						expand = 'none',
						layout = wibox.layout.fixed.vertical
					},
					{
						layout = wibox.layout.fixed.vertical,
						{
							locker_container,
							locker_widget,
							{
								layout = wibox.layout.align.vertical,
								expand = 'none',
								nil,
								{
									layout = wibox.layout.align.horizontal,
									expand = 'none',
									nil,
									user_image,
									nil
								},
								nil,
							},
							layout = wibox.layout.stack
						},
						user_text,
						caps_text
					},
				},
				nil
			},
			nil
		},
		layout = wibox.layout.stack
	}

	-- TODO remove ability to pass false to this signal (only show lockscreen)
	-- to prevent other processes from hiding it
	-- should only hide after authenticated
	awesome.connect_signal(
		'desktop::lock-screen',
		function (visible)
			if type(visible) ~= 'boolean' then
				visible = not lockscreen.visible
			end

			if visible then
				time_text:emit_signal('widget::redraw_needed')
				check_caps_state()
				password_grabber:start()
			else
				password_grabber:stop()
			end

			lockscreen.visible = visible
			is_visible = visible
		end)

	return lockscreen
end

-- cover additional monitors
local function create_extended_lockscreen(s)
	local extended_lockscreen = wibox {
		screen = s,
		visible = false,
		ontop = true,
		type = 'splash',
		x = s.geometry.x,
		y = s.geometry.y,
		width = s.geometry.width,
		height = s.geometry.height,
		fg = beautiful.fg_normal,
		bg = beautiful.background
	}

	extended_lockscreen:setup {
		image = wallpaper,
		resize = true,
		horizontal_fit_policy = 'fit',
		vertical_fit_policy = 'fit',
		widget = wibox.widget.imagebox
	}

	awesome.connect_signal(
		'desktop::lock-screen',
		function (visible)
			if type(visible) == 'boolean' then
				extended_lockscreen.visible = visible
			else
				extended_lockscreen.visible = not extended_lockscreen.visible
			end
		end)

	return extended_lockscreen
end

-- signals

screen.connect_signal(
	'request::desktop_decoration', function (s)
		local primary_index = screen.primary.index or 1

		if s.index == primary_index then
			create_main_lockscreen(s)
		else
			create_extended_lockscreen(s)
		end
	end)

naughty.connect_signal(
	'request::display', -- a notification is requesting to be displayed
	function (_)
		-- do not show notifications when the lockscreen is visible
		if is_visible then
			naughty.destroy_all_notifications(nil, 1)
		end
	end)
