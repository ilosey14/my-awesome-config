local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')
local wibox = require('wibox')

local icons = require('config.theme.icons')
local user = require('lib.user')
local widgets = require('widgets')

local dpi = beautiful.xresources.apply_dpi
local margins = beautiful.margins
local spacing = beautiful.spacing
local button_spacing = dpi(32)

local message_table = {
	'See you later, alligator!',
	'Peace out!',
	'In a while, crocodile.',
	'Adios, amigo.',
	'Begone!',
	'Arrivederci.',
	'Au revoir!',
	'Sayonara!',
	'Ciao!'
}

local greeter_message = wibox.widget {
	text = message_table[math.random(#message_table)],
	font = beautiful.font,
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local profile_name = wibox.widget {
	markup = user.format('%{name} @ %{host}'),
	font = beautiful.font_bold,
	align = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local profile_image = wibox.widget {
	image = user.get_value('image'),
	resize = true,
	forced_height = dpi(140),
	clip_shape = gears.shape.circle,
	widget = wibox.widget.imagebox
}

local create_action_button = function (label, icon, callback)
	local text = wibox.widget {
		text = label,
		font = beautiful.font,
		align = 'center',
		valign = 'center',
		widget = wibox.widget.textbox
	}

	local button = wibox.widget {
		{
			{
				{
					{
						image = icon,
						stylesheet = beautiful.icon_stylesheet,
						widget = wibox.widget.imagebox
					},
					margins = margins,
					widget = wibox.container.margin
				},
				bg = beautiful.groups_bg,
				widget = wibox.container.background
			},
			shape = gears.shape.rounded_rect,
			forced_width = dpi(90),
			forced_height = dpi(90),
			widget = widgets.clickable
		},
		left = dpi(24),
		right = dpi(24),
		widget = wibox.container.margin
	}

	local widget = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		spacing = spacing,
		button,
		text
	}

	widget:buttons {
		awful.button(
			{ },
			awful.button.names.LEFT,
			nil,
			callback)
	}

	return widget
end

local suspend_command = function ()
	awesome.emit_signal('desktop::exit-screen')
	awesome.emit_signal('desktop::lock-screen:visible', true)
	awful.spawn('systemctl suspend')
end

local logout_command = function ()
	awesome.quit()
end

local lock_command = function ()
	awesome.emit_signal('desktop::exit-screen')
	awesome.emit_signal('desktop::lock-screen:visible', true)
end

local poweroff_command = function ()
	awful.spawn('poweroff')
end

local reboot_command = function ()
	awful.spawn('reboot')
end

local poweroff = create_action_button('Shutdown', icons.power, poweroff_command)
local reboot   = create_action_button('Restart', icons.restart, reboot_command)
local suspend  = create_action_button('Sleep', icons.sleep, suspend_command)
local logout   = create_action_button('Logout', icons.logout, logout_command)
local lock     = create_action_button('Lock', icons.lock, lock_command)

local keygrabber = awful.keygrabber {
	stop_event = 'release',
	keypressed_callback = function (self, mod, key, command)
		if key == 's' then
			suspend_command()

		elseif key == 'e' then
			logout_command()

		elseif key == 'l' then
			lock_command()

		elseif key == 'p' then
			poweroff_command()

		elseif key == 'r' then
			reboot_command()

		elseif key == 'Escape' or key == 'q' or key == 'x' then
			awesome.emit_signal('desktop::exit-screen')
		end
	end
}

local create_exit_screen = function (s)
	local exit_screen = wibox
	{
		screen = s,
		type = 'splash',
		visible = false,
		ontop = true,
		bg = beautiful.bg_normal,
		fg = beautiful.fg_normal,
		height = s.geometry.height,
		width = s.geometry.width,
		x = s.geometry.x,
		y = s.geometry.y
	}

	exit_screen:buttons {
		awful.button(
			{ },
			awful.button.names.MIDDLE,
			function () awesome.emit_signal('desktop::exit-screen') end
			),
		awful.button(
			{ },
			awful.button.names.RIGHT,
			function () awesome.emit_signal('desktop::exit-screen') end
		)
	}

	exit_screen:setup {
		layout = wibox.layout.align.vertical,
		expand = 'none',
		nil,
		{
			layout = wibox.layout.align.vertical,
			{
				nil,
				{
					layout = wibox.layout.fixed.vertical,
					spacing = spacing,
					{
						layout = wibox.layout.align.vertical,
						expand = 'none',
						nil,
						{
							layout = wibox.layout.align.horizontal,
							expand = 'none',
							nil,
							profile_image,
							nil
						},
						nil
					},
					profile_name
				},
				nil,
				expand = 'none',
				layout = wibox.layout.align.horizontal
			},
			{
				layout = wibox.layout.align.horizontal,
				expand = 'none',
				nil,
				{
					widget = wibox.container.margin,
					margins = margins,
					greeter_message
				},
				nil
			},
			{
				layout = wibox.layout.align.horizontal,
				expand = 'none',
				nil,
				{
					{
						{
							poweroff,
							reboot,
							suspend,
							logout,
							lock,
							layout = wibox.layout.fixed.horizontal
						},
						spacing = button_spacing,
						layout = wibox.layout.fixed.vertical
					},
					widget = wibox.container.margin,
					margins = margins
				},
				nil
			}
		},
		nil
	}

	-- signals
	awesome.connect_signal(
		'desktop::exit-screen',
		function (visible)
			if type(visible) == 'boolean' then
				exit_screen.visible = visible
			else
				exit_screen.visible = not exit_screen.visible
			end

			if exit_screen.visible then
				keygrabber:start()
			else
				keygrabber:stop()
			end
		end)
end

screen.connect_signal('request::desktop_decoration', create_exit_screen)
--screen.connect_signal('removed', create_exit_screen)

--
return {
	create_button = require('desktop.exit-screen.create-button')
}
