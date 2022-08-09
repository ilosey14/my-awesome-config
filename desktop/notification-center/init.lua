local awful = require('awful')
local beautiful = require('beautiful')
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
local spacing = beautiful.spacing

-- TODO refactor notification (and center) structure
-- TODO to use a single/central widget "fAcToRy"
require('desktop.notification-center.notifications')

--
-- make notification center
--

-- Set the notification center geometry
local panel_width = dpi(384)
local button_size = dpi(16)

local clear_all_button = wibox.widget {
	{
		image = icons.clear_all,
		stylesheet = beautiful.icon_stylesheet,
		resize = true,
		forced_height = button_size,
		forced_width = button_size,
		widget = wibox.widget.imagebox
	},
	widget = widgets.clickable
}

local notification_list = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	spacing = spacing
}

clear_all_button:buttons {
	awful.button(
		{ },
		awful.button.names.LEFT,
		nil,
		function () notification_list:reset() end
	)
}

local panel = awful.popup {
	widget = {
		{
			{
				layout = wibox.layout.fixed.vertical,
				spacing = spacing,
				forced_width = panel_width,
				{
					{
						{
							expand = 'none',
							layout = wibox.layout.fixed.vertical,
							spacing = spacing,
							{
								layout = wibox.layout.align.horizontal,
								expand = 'none',
								{
									text = 'Notification Center',
									font = 'Roboto Bold 14',
									align = 'left',
									valign = 'center',
									widget = wibox.widget.textbox
								},
								nil,
								clear_all_button
							},
							{
								notification_list,
								margins = margins,
								widget = wibox.container.margin,
							}
						},
						margins = margins,
						widget = wibox.container.margin
					},
					shape = beautiful.shapes.rounded_rect,
					widget = wibox.container.margin,
				}
			},
			margins = margins,
			widget = wibox.container.margin
		},
		id = 'notification_center',
		bg = beautiful.primary,
		shape = beautiful.shapes.rounded_rect,
		widget = wibox.container.background
	},
	type = 'popup_menu',
	visible = false,
	ontop = true,
	width = dpi(panel_width),
	maximum_width = dpi(panel_width),
	bg = beautiful.transparent,
	fg = beautiful.fg_normal,
	shape = beautiful.shapes.rectangle
}

--

local action_template = {
	{
		{
			{
				{
					id = 'text_role',
					font = beautiful.font,
					widget = wibox.widget.textbox
				},
				margins = margins,
				widget = wibox.container.margin
			},
			widget = widgets.clickable
		},
		bg = beautiful.transparent,
		forced_width = dpi(24),
		shape = beautiful.shapes.rounded_rect,
		widget = wibox.container.background
	},
	margins = margins,
	widget = wibox.container.margin
}

local function add_to_list(n)
	local title = string.format('<b>%s</b>', n.title or settings.title)
	local icon = n.icon or n.app_icon or icons[n.icon] or settings.icon
	local app_name = (#n.app_name == 0) and n.app_name or settings.app_name

	local clear_button = wibox.widget {
		image = icons.clear,
		stylesheet = beautiful.icon_stylesheet,
		resize = true,
		forced_height = button_size,
		forced_width = button_size,
		widget = wibox.widget.imagebox
	}

	local notification = wibox.widget {
		{
			{
				layout = wibox.layout.fixed.vertical,
				spacing = spacing,
				{
					layout = wibox.layout.align.horizontal,
					expand = 'none',
					-- icon, app name, and clear button
					{
						layout = wibox.layout.fixed.horizontal,
						spacing = spacing,
						{
							image = icon,
							stylesheet = beautiful.icon_stylesheet,
							resize = true,
							forced_height = dpi(24),
							forced_width = dpi(24),
							widget = wibox.widget.imagebox
						},
						{
							markup = title,
							font = beautiful.font,
							align = 'left',
							valign = 'center',
							widget = wibox.widget.textbox
						}
					},
					nil,
					{
						{
							{
								clear_button,
								margins = margins,
								widget = wibox.container.margin
							},
							widget = widgets.clickable
						},
						shape = beautiful.shapes.circle,
						widget = wibox.container.background
					}
				},
				{
					layout = wibox.layout.fixed.vertical,
					spacing = spacing,
					-- title and message
					{
						layout = wibox.layout.fixed.vertical,
						{
							text = app_name,
							font = beautiful.font,
							align = 'left',
							valign = 'center',
							widget = wibox.widget.textbox
						},
						{
							markup = n.message,
							font = beautiful.font,
							align = 'left',
							valign = 'center',
							widget = wibox.widget.textbox
						}
					},
					-- actions
					{
						notification = n,
						base_layout = wibox.widget {
							layout = wibox.layout.flex.horizontal,
							spacing = spacing
						},
						widget_template = action_template,
						style = {
							underline_normal = false,
							underline_selected = true
						},
						widget = naughty.list.actions
					}
				}
			},
			margins = margins,
			widget = wibox.container.margin
		},
		bg = beautiful.dark_primary,
		shape = beautiful.shapes.rounded_rect,
		widget = wibox.container.background
	}

	clear_button:buttons {
		awful.button(
			{ },
			awful.button.names.LEFT,
			nil,
			function () notification_list:remove_widgets(notification) end)
	}

	notification_list:insert(1, notification)
	-- notification_list:insert(1, n.widget_template)
end

local set_nc_screen = function (s)
	panel.screen = s
	panel.maximum_height = dpi(s.geometry.height - 2 * margins)

	awful.placement.top_right(
		panel,
		{
			honor_workarea = true,
			parent = s,
			margins = {
				top = dpi(44),
				right = margins
			}
		}
	)
end

local open_panel = function (s)
	set_nc_screen(s)

	awesome.emit_signal('desktop::mask:visible', true, s)
	panel.visible = true
end

local close_panel = function ()
	awesome.emit_signal('desktop::mask:visible', false)
	panel.visible = false
end

-- expose functionality

local notification_center = {
	is_open = false,
	screen = nil,
	panel = panel
}

---@param s any Shows on the give screen.
function notification_center:show(s)
	if self.is_open then return end

	self.is_open = true
	self.screen = s or awful.screen.focused()

	open_panel(s)
end

---@param s? any When provided, hides only if open on the given screen.
function notification_center:hide(s)
	if not self.is_open then return end
	if s and self.screen.index ~= s.index then return end

	self.is_open = false
	self.screen = nil

	close_panel()
end

-- signals
-- TODO move notification directly to list when opening notification center

naughty.connect_signal(
	'destroyed',
	function (n, reason)
		-- if timed out, add to notification center
		if reason == 1 then
			add_to_list(n)
		end
	end)

awesome.connect_signal(
	'desktop::notification-center',
	function (is_visible, s)
		if type(is_visible) ~= 'boolean' then
			is_visible = not notification_center.is_open
		end

		if is_visible then
			awesome.emit_signal('desktop::mask:visible', false)
			notification_center:show(s or awful.screen.focused())
		else
			notification_center:hide(s)
		end
	end)

awesome.connect_signal(
	'desktop::mask:dismissed',
	function () notification_center:hide() end)

--
return {
	create_button = require('desktop.notification-center.create-button')
}
