local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')

local icons = require('config.theme.icons')

local tag_defaults = {
	gap_single_client = true,
	gap = beautiful.useless_gap,
	layout = awful.layout.suit.floating,
	selected = true
}
local layout_defaults = {
	awful.layout.suit.floating,
	awful.layout.suit.tile,
	awful.layout.suit.spiral.dwindle
}
local tag_count = 0

local function next_tag_props()
	tag_count = tag_count + 1

	return gears.table.join(
		{ name = string.format('Desktop %i', tag_count) },
		tag_defaults
	)
end

local tags = { next_tag_props() }

-- icons

beautiful.layout_floating = icons.layout_floating
beautiful.layout_tile = icons.layout_tile
beautiful.layout_dwindle = icons.layout_dwindle

-- signals

tag.connect_signal(
	'request::default_layouts',
	function ()
		awful.layout.append_default_layouts(layout_defaults)
	end)

screen.connect_signal(
	'request::desktop_decoration',
	function (s)
		for _, tag in ipairs(tags) do
			tag.screen = s
			awful.tag.add(tag.name, tag)
		end
	end)

awesome.connect_signal(
	'config::tags:add',
	function (s)
		local new_tag = next_tag_props()
		local screens = s and ipairs { s } or screen

		table.insert(tags, new_tag)

		for _, s_ in screens do
			new_tag.screen = s_
			awful.tag.add(new_tag.name, new_tag):view_only()
		end
	end)
