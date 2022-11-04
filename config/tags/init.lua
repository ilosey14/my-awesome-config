local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')

local icons = require('config.theme.icons')

local tag_defaults = {
	gap_single_client = true,
	gap = beautiful.useless_gap,
	layout = awful.layout.suit.floating
}

local tags = {
	{
		name = 'Default',
		selected = true
	}
}

-- icons

beautiful.layout_floating = icons.layout_floating
beautiful.layout_tile = icons.layout_tile
beautiful.layout_dwindle = icons.layout_dwindle

-- signals

tag.connect_signal(
	'request::default_layouts',
	function ()
		awful.layout.append_default_layouts({
			awful.layout.suit.floating,
			awful.layout.suit.tile,
			awful.layout.suit.spiral.dwindle
		})
	end)

screen.connect_signal(
	'request::desktop_decoration',
	function (s)
		for _, tag in pairs(tags) do
			awful.tag.add(
				tag.name,
				gears.table.join(tag_defaults, tag, { screen = s }))
		end
	end)
