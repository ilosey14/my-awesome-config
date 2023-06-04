local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local dpi = beautiful.xresources.apply_dpi
local margins = beautiful.margins

-- systray popup

local systray_popup = awful.popup {
	widget = {
		{
			{
				base_size = dpi(32),
				horizontal = true,
				widget = wibox.widget.systray
			},
			margins = margins,
			widget = wibox.container.margin
		},
		bg = beautiful.primary,
		shape = beautiful.shapes.rounded_rect,
		widget = wibox.container.background
	},
	ontop = true,
	width = 1, -- forces initial placement
	minimum_height = dpi(24),
	minimum_width = dpi(24),
	maximum_width = dpi(256),
	bg = beautiful.transparent,
	shape = beautiful.shapes.rectangle,
	type = 'popup_menu',
	visible = false
}

local function show_systray(s)
	systray_popup.screen = s or awful.screen.focused()

	awful.placement.top_right(
		systray_popup,
		{
			honor_workarea = true,
			parent = s,
			margins = margins
		})

	awesome.emit_signal('desktop::mask:visible', true, systray_popup.screen)
	systray_popup.visible = true
end

local function hide_systray()
	awesome.emit_signal('desktop::mask:visible', false)
	systray_popup.visible = false
end

awesome.connect_signal(
	'desktop::systray',
	function (is_visible)
		if type(is_visible) ~= 'boolean' then
			is_visible = not is_visible
		end

		if is_visible then
			show_systray()
		else
			hide_systray()
		end
	end)

awesome.connect_signal(
	'desktop::mask:dismissed',
	hide_systray)

-- limit systray to primary screen
--return awful.widget.only_on_screen(toggle_button, 'primary')
return {
	create_button = require('desktop.systray.create-button')
}
