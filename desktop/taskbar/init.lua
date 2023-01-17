local beautiful = require('beautiful')
local wibox = require('wibox')

local height = beautiful.taskbar_height
local margins = beautiful.taskbar_margin
local shape = beautiful.shapes[beautiful.taskbar_shape]
local global_is_visible = true
local screen_is_fullscreen = { }

local function is_fullscreen(s)
	for _, c in ipairs(client.get(s)) do
		if c.fullscreen then return true end
	end

	return false
end

local function create_screen_tbl()
	while #screen_is_fullscreen > 0 do
		table.remove(screen_is_fullscreen)
	end

	for s in screen do
		screen_is_fullscreen[s.index] = is_fullscreen(s)
	end
end

local function create_taskbar(s)
	local panel = wibox
	{
		screen = s,
		type = 'dock',
		ontop = true,
		visible = true,
		height = height,
		width = s.geometry.width - 2 * margins,
		x = s.geometry.x + margins,
		y = s.geometry.y + margins,
		stretch = false,
		bg = beautiful.background,
		fg = beautiful.fg_normal,
		shape = shape
	}

	panel:struts { top = height + margins }

	panel:connect_signal(
		'mouse::enter',
		function ()
			local w = mouse.current_wibox

			if w then w.cursor = 'left_ptr' end
		end)

	local is_primary = (s.index == screen.primary.index)

	local app_drawer			= require('desktop.app-drawer')
	local search				= require('desktop.search')
	local pinned_apps			= require('desktop.pinned-apps')

	local task_list				= require('desktop.task-list')

	local key_state				= require('desktop.key-state')
	local systray				= require('desktop.systray')
	local network				= require('desktop.network')
	local battery				= require('desktop.battery')
	local layout				= require('desktop.layout')
	local control_center 		= require('desktop.control-center')
	local notification_center	= require('desktop.notification-center')
	local clock					= require('desktop.clock')

	panel:setup {
		layout = wibox.layout.align.horizontal,
		expand = 'inside',

		{
			layout = wibox.layout.fixed.horizontal,
			spacing = beautiful.useless_gap,

			app_drawer.create_button(),
			is_primary and search.create_button(),
			is_primary and pinned_apps.create_list(),
			{
				{
					{
						text = '|',
						widget = wibox.widget.textbox
					},
					fg = beautiful.secondary,
					widget = wibox.container.background
				},
				margins = margins,
				widget = wibox.container.margin
			}
		},
		{
			layout = wibox.layout.fixed.horizontal,
			task_list.create_task_list(s)
		},
		{
			layout = wibox.layout.fixed.horizontal,
			spacing = beautiful.useless_gap,

			key_state,
			is_primary and systray.create_button(),
			is_primary and network.create_button(),
			battery.create_button(),
			layout.create_button(s),
			is_primary and control_center.create_button(s),
			is_primary and notification_center.create_button(s),
			is_primary and clock.create_button(s)
		}
	}

	-- connect signal
	awesome.connect_signal(
		'desktop::taskbar:visible',
		function (s_, set_visible)
			if not s_ then s_ = s
			elseif s_.index ~= s.index then return
			end

			-- set explicitly considering the global state
			if type(set_visible) == 'boolean' then
				panel.visible = set_visible and global_is_visible
				screen_is_fullscreen[s.index] = not set_visible

			-- otherwise keep fullscreen
			elseif screen_is_fullscreen[s.index] then
				panel.visible = false

			-- and set all other screen to the global state
			else
				panel.visible = global_is_visible
			end

			awesome.emit_signal('desktop::taskbar:event', panel)
		end)

	--
	return panel
end

-- signals

screen.connect_signal('request::desktop_decoration', create_screen_tbl)
screen.connect_signal('request::create', create_screen_tbl)
screen.connect_signal('request::remove', create_screen_tbl)

awesome.connect_signal(
		'desktop::taskbar:visible',
		function (s, is_visible)
			-- catch/sync state for all screens before setting them
			if s and s.index ~= screen.primary.index then return end

			if type(is_visible) == 'boolean' then
				global_is_visible = is_visible
			else
				global_is_visible = not global_is_visible
			end
		end)

--
return {
	create_taskbar = create_taskbar
}
