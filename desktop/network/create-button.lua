local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local apps = require('config.apps')
local icons = require('config.theme.icons')
local widgets = require('widgets')

local margins = beautiful.margins

local function create_button()
	local icon = wibox.widget {
		image = icons.network,
		stylesheet = beautiful.icon_stylesheet,
		resize = true,
		widget = wibox.widget.imagebox
	}

	local button = wibox.widget {
		{
			icon,
			margins = margins,
			widget = wibox.container.margin
		},
		widget = widgets.clickable
	}

	button:add_button(
		awful.button(
			{ },
			1,
			nil,
			function () awful.spawn(apps.default.network_manager, false) end
		))

	local tooltip = awful.tooltip {
		text = '...',
		objects = { button },
		mode = 'outside',
		align = 'right',
		preferred_positions = { 'bottom', 'left', 'right' },
		margins = margins
	}

	-- update button
	awesome.connect_signal(
		'desktop::network',
		function (info)
			local if_name = info.if_name
			local if_type = info.if_type
			local is_connected = info.is_connected
			local ip = info.ip4 or info.ip6
			local ping = info.ping
			local strength = info.strength

			-- icon
			local status = ''

			if not if_type or #if_type == 0 then
				if_type = 'network'
			end

			if not is_connected then
				status = '_off'
			elseif if_type == 'wifi' then
				if strength >= 67 then
					status = '_strong'
				elseif strength >= 33 then
					status = '_medium'
				else
					status = '_weak'
				end
			else
				strength = 'N/A '
			end

			icon.image = icons[string.format('%s%s', if_type, status)]

			-- tooltip
			tooltip:set_markup(
				string.format(
					'<b>%s</b>\nName: %s\nIs Connected: %s\nIP: %s\nPing: %g ms\nStrength: %.f%%',
					string.upper(if_type or ''),
					if_name or 'N/A',
					(is_connected and 'Yes') or 'No',
					ip or 'N/A',
					ping or 0,
					strength or 0
				))
		end)

	return button
end

return create_button
