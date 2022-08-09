local awful = require('awful')
local beautiful = require('beautiful')
local utils = require('menubar.utils')
local wibox = require('wibox')

local apps = require('config.apps')
local widgets = require('widgets')

local app_dirs = {
	os.getenv('HOME') .. '/.local/share/applications',
	'/usr/share/applications'
}
local gap = beautiful.useless_gap
local pinned_apps = { }
local spacing = beautiful.spacing

local function cache_list()
	if #pinned_apps > 0 then return pinned_apps end

	for _, app in ipairs(apps.pinned) do
		-- find app
		local desktop = nil

		for _, dir in ipairs(app_dirs) do
			desktop = utils.parse_desktop_file(string.format('%s/%s.desktop', dir, app))

			if desktop then
				table.insert(pinned_apps, desktop)
				break
			end
		end
	end

	return pinned_apps
end

local function create_list()
	local apps = cache_list()
	local list = wibox.widget {
		layout = wibox.layout.fixed.horizontal,
		spacing = spacing
	}

	if #apps <= 0 then return list end

	-- append client icon button
	for _, app in ipairs(apps) do
		-- spawn without any field codes (not parsing them at this time)
		-- https://specifications.freedesktop.org/desktop-entry-spec/latest/ar01s07.html
		local exec = string.gsub(app.Exec, '%%%a', '')

		local button = wibox.widget {
			{
				image = app.icon_path,
				-- stylesheet = beautiful.icon_stylesheet
				resize = true,
				widget = wibox.widget.imagebox
			},
			buttons = {
				awful.button {
					modifiers = { },
					button = awful.button.names.LEFT,
					on_press = function () awful.spawn(exec) end
				}
			},
			margins = gap,
			widget = wibox.container.margin
		}

		list:add {
			button,
			widget = widgets.clickable
		}
	end

	return list
end

-- signals

--[[ TODO
client.connect_signal(
	'request::manage',
	function (c)
		-- if the command (first word) in app.Exec matches c.instance or c.class
		-- then hide the pinned app
		-- add task list context menu option to open a new instance of that app
	end)

client.connect_signal(
	'request::unmanage',
	function (c)
		-- same as above but show
	end)
]]

--
return {
	create_list = create_list
}
