local beautiful = require('beautiful')
local gears = require('gears')
local menubar = require('menubar')
local naughty = require('naughty')
local wibox = require('wibox')

local config = require('lib.config')
local icons = require('config.theme.icons')
local widgets = require('widgets')

local dpi = beautiful.xresources.apply_dpi
local settings = config.load(
	'desktop.notification-center.settings',
	{
		screen = screen,
		dpi = dpi,
		icons = icons
	})
local margins = beautiful.margins

-- theme
naughty.config.padding = settings.padding
naughty.config.spacing = settings.spacing
naughty.config.icon_dirs = settings.icon_dirs
naughty.config.icon_formats = settings.icon_formats

-- defaults
naughty.config.defaults.timeout = settings.timeout
naughty.config.defaults.text = settings.text
naughty.config.defaults.ontop = settings.ontop
naughty.config.defaults.icon_size = settings.icon_size
naughty.config.defaults.title = settings.title
naughty.config.defaults.margin = margins
naughty.config.defaults.border_width = settings.border_width
naughty.config.defaults.position = settings.position
naughty.config.defaults.shape = beautiful.shapes.rounded_rect

-- presets
naughty.config.presets.low = settings.low
naughty.config.presets.normal = settings.normal
naughty.config.presets.critical = settings.critical

-- templates

local actions_template = {
	{
		{
			{
				{
					id = 'text_role',
					font = beautiful.font,
					widget = wibox.widget.textbox
				},
				widget = wibox.container.place
			},
			widget = widgets.clickable
		},
		bg = beautiful.transparent,
		shape = gears.shape.rounded_rect,
		forced_height = dpi(30),
		widget = wibox.container.background
	},
	margins = margins,
	widget  = wibox.container.margin
}

local app_name = wibox.widget {
	markup = '',
	font = beautiful.font,
	align = 'left',
	valign = 'center',
	widget = wibox.widget.textbox
}

local notification_template = wibox.widget {
	{
		{
			{
				{
					naughty.widget.title,
					margins = margins,
					widget = wibox.container.margin,
				},
				bg = beautiful.dark_primary,
				widget = wibox.container.background,
			},
			{
				{
					{
						stylesheet = beautiful.icon_stylesheet,
						resize_strategy = 'center',
						widget = naughty.widget.icon,
					},
					margins = margins,
					widget = wibox.container.margin,
				},
				{
					{
						layout = wibox.layout.align.vertical,
						expand = 'none',
						nil,
						{
							app_name,
							{
								align = 'left',
								widget = naughty.widget.message,
							},
							layout = wibox.layout.fixed.vertical
						},
						nil
					},
					margins = margins,
					widget = wibox.container.margin,
				},
				layout = wibox.layout.fixed.horizontal,
			},
			fill_space = true,
			spacing = settings.spacing,
			layout = wibox.layout.fixed.vertical,
		},
		margins = 0,
		widget  = wibox.container.margin,
	},
	bg = beautiful.transparent,
	widget = wibox.container.background,
}

-- https://awesomewm.org/apidoc/popups_and_bars/naughty.layout.box.html
local function create_notification(n)
	local actions_widget = wibox.widget {
		notification = n,
		base_layout = wibox.widget {
			spacing = settings.spacing,
			layout = wibox.layout.flex.horizontal
		},
		widget_template = actions_template,
		style = {
			underline_normal = false,
			underline_selected = true
		},
		widget = naughty.list.actions
	}

	app_name:set_markup((#n.app_name > 0) and n.app_name or settings.app_name)

	return wibox.widget	{
		{
			{
				{
					notification_template,
					actions_widget,
					spacing = settings.spacing,
					layout = wibox.layout.fixed.vertical,
				},
				id = 'background_role',
				bg = beautiful.transparent,
				widget = naughty.container.background,
			},
			strategy = 'min',
			width = dpi(250),
			widget = wibox.container.constraint,
		},
		strategy = 'max',
		height = dpi(250),
		width = dpi(250),
		widget = wibox.container.constraint
	}
end

-- errors
naughty.connect_signal(
	'request::display_error',
	function (message, startup)
		naughty.notification {
			urgency = 'critical',
			title = string.format('Oops, an error happened%s!', (startup and ' during startup') or ''),
			message = message,
			app_name = settings.app_name,
			icon = beautiful.awesome_icon
		}
	end)

-- if an icons could not be loaded
-- https://awesomewm.org/apidoc/libraries/naughty.html#request::icon
naughty.connect_signal(
	'request::icon',
	function (n, context, hints)
		if context ~= 'app_icon' then return end

		local path = menubar.utils.lookup_icon(hints.app_icon) or
			menubar.utils.lookup_icon(hints.app_icon:lower())

		if path then
			n.icon = path
		else
			n.icon = icons.notification
		end
	end)

-- display a notification
naughty.connect_signal(
	'request::display',
	function (n)
		naughty.layout.box {
			notification = n,
			type = 'notification',
			shape = beautiful.shapes.rounded_rect,
			widget_template = create_notification(n)
		}

		-- check for do not disturb and dismiss notifications
		awesome.emit_signal(
			'desktop::do-not-disturb:get',
			function (do_not_disturb)
				if do_not_disturb then
					naughty.destroy_all_notifications(nil, 1)
				end
			end)
	end)
