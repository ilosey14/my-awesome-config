local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local config = require('lib.config')
local user = require('lib.user')

-- load theme settings
local dot_config = config.load('config.theme.theme')
local theme_name = (dot_config and dot_config.theme_name) or 'default'
local theme_dir = string.format('%s/config/theme/%s', user.get_value('config_dir'), theme_name)

-- load theme file
local theme_config = config.load(
	string.format('config.theme.%s.theme', theme_name),
	{
		dpi = beautiful.xresources.apply_dpi,
		gtk = beautiful.gtk.get_theme_variables()
	})

-- DEV parse into beautiful theme table
local theme = require('config.theme.default')(theme_config)

-- flatten groups into root theme table
for key, value in pairs(theme_config) do
	if type(value) == 'table' then
		for k, v in pairs(value) do
			theme[k] = v
		end
	else
		theme[key] = value
	end
end

-- TODO need config schema
-- HACK to prepend expected paths
theme.wallpaper = string.format('%s/wallpaper/%s', theme_dir, theme.desktop_wallpaper)
theme.lockscreen_wallpaper = string.format('%s/wallpaper/%s', theme_dir, theme.lockscreen_wallpaper)

-- load theme into beautiful
beautiful.init(theme)

-- set wallpaper listener
-- https://awesomewm.org/apidoc/popups_and_bars/awful.wallpaper.html
screen.connect_signal(
	'request::wallpaper',
	function (s)
		local wallpaper_type = type(beautiful.wallpaper)
		local wallpaper = {
			screen = s,
			bg = '#000000'
		}

		-- set wallpaper widget properties accordingly
		if wallpaper_type == 'string' then
			local first_char = string.sub(beautiful.wallpaper, 1, 1)

			-- check for color
			if first_char == '#' then
				wallpaper.bg = beautiful.wallpaper

			-- check for path/image
			elseif first_char == '/' then
				wallpaper.widget = {
					image = beautiful.wallpaper,
					resize = true,
					horizontal_fit_policy = 'fit',
					vertical_fit_policy = 'fit',
					scaling_quality = 'best',
					widget = wibox.widget.imagebox
				}
			end
		elseif wallpaper_type == 'function' then
			wallpaper.widget = beautiful.wallpaper()
		end

		-- set wallpaper
		awful.wallpaper(wallpaper)
	end
)
