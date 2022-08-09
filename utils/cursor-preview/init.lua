local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local widgets = require('widgets')

local margins = beautiful.margins

local grid = wibox.widget {
	homogeneous = false,
	min_col_size = 100,
	min_row_size = 16,
	forced_num_cols = 8,
	forced_num_rows = 10,
	spacing = beautiful.spacing,
	layout = wibox.layout.grid.vertical
}

local popup = awful.popup {
	widget = {
		{
			layout = wibox.layout.fixed.vertical,
			spacing = margins,
			{
				text = '[close]',
				align = 'right',
				buttons = {
					awful.button {
						modifiers = { },
						button = awful.button.names.LEFT,
						on_press = function () awesome.emit_signal('utils::cursor-preview') end
					}
				},
				widget = wibox.widget.textbox
			},
			grid
		},
		margins = margins,
		widget = wibox.container.margin
	},
	type = 'popup_menu',
	ontop = true,
	visible = false,
	bg = beautiful.primary,
	placement = awful.placement.centered,
	shape = beautiful.shapes.rounded_rect
}

local function show_popup(s)
	popup.screen = s
	popup.visible = true
end

local function hide_popup()
	popup.visible = false
end

local function toggle_popup(s)
	if popup.visible then
		hide_popup()
	else
		show_popup(s)
	end
end

local function create_preview(cursor_name)
	local preview = wibox.widget {
		{
			{
				text = cursor_name,
				align = 'center',
				widget = wibox.widget.textbox
			},
			margins = margins,
			widget = wibox.container.margin
		},
		bg = beautiful.secondary,
		widget = wibox.container.background
	}

	widgets.clickable.connect_signals(preview, cursor_name)

	return preview
end

-- get cursor names list
-- https://pissedoffadmins.com/os/linux/xsetroot-cursor_name-list.html

awful.spawn.easy_async_with_shell(
	"awk 'NR==33,EOF { print $2 }' /usr/include/X11/cursorfont.h | cut -d_ -f2-9",
	function (stdout)
		local count = 0

		for line in string.gmatch(stdout, '%s*(.-)%s*\n') do
			grid:add(create_preview(line))
			count = count + 1
		end
	end)

-- signals

awesome.connect_signal(
	'utils::cursor-preview',
	function (is_visible, s)
		if type(is_visible) == 'boolean' then
			if is_visible then
				show_popup(s)
			else
				hide_popup()
			end
		else
			toggle_popup(s)
		end
	end)
