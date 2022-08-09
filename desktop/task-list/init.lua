local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local timers = require('lib.timers')

local dpi = beautiful.xresources.apply_dpi
local widgets = require('widgets')

local gap = beautiful.useless_gap
local margins = beautiful.margins
local max_text_width = dpi(256)
local taskbar_bottom = beautiful.taskbar_margin + beautiful.taskbar_height

-- tooltip

local task_list_tooltip = awful.tooltip {
	delay_show = 1,
	mode = 'outside',
	preferred_positions = { 'bottom' },
	preferred_alignments = { 'middle', 'front', 'back' },
	gaps = gap,
	shape = beautiful.shapes.rounded_rect
}

local function add_tooltip(widget, client)
	task_list_tooltip:add_to_object(widget)
	widget:connect_signal('mouse::enter', function ()
		task_list_tooltip:set_text(client.name)
	end)
end

-- context menu

---@param text string
---@param on_click function
---@return any
local function create_context_menu_item(text, on_click)
	return widgets.clickable {
		{
			text = text,
			widget = wibox.widget.textbox
		},
		margins = gap,
		widget = wibox.container.margin,
		buttons = {
			awful.button {
				modifiers = { },
				button = awful.button.names.LEFT,
				on_press = on_click
			}
		}
	}
end

local menu_client = nil
local context_menu = awful.popup {
	widget = {
		{
			layout = wibox.layout.fixed.vertical,
			create_context_menu_item('❌  Close',      function () menu_client:kill() end),
			{
				margins = gap,
				widget = wibox.container.margin
			},
			create_context_menu_item('⏫  Maximize',   function () menu_client.maximized = not menu_client.maximized end),
			create_context_menu_item('⏬  Minimize',   function () menu_client.minimized = not menu_client.minimized end),
			create_context_menu_item('🖥️  Fullscreen', function ()
				menu_client.fullscreen = not menu_client.fullscreen

				if menu_client.fullscreen then
					menu_client:activate { raise = true }
				end
			end),
			{
				margins = gap,
				widget = wibox.container.margin
			},
			create_context_menu_item('☁️  Float',      function () menu_client.floating  = not menu_client.floating end),
			create_context_menu_item('🚀  On Top',     function () menu_client.ontop     = not menu_client.ontop end),
			create_context_menu_item('🚥  Titlebars',  function () client.emit_signal('titlebar:visible', menu_client) end),
		},
		margins = margins,
		widget = wibox.container.margin
	},
	type = 'popup_menu',
	preferred_positions = { 'bottom' },
	preferred_alignments = { 'middle', 'front', 'back' },
	ontop = true,
	shape = beautiful.shapes.rounded_rect,
	bg = beautiful.background,
	fg = beautiful.fg_normal,
	visible = false
}

function context_menu:show(client)
	if self.visible then return end
	if client == nil then return end

	-- placement
	-- the current widget geometry is the icon or label under the mouse.
	-- get the full task list button which is
	-- the second to last geometry in the current geometries table
	local mouse_coords = mouse.coords()
	local geo_list = mouse.current_widget_geometries
	local geo = geo_list[#geo_list - 1]

	awful.placement.top(context_menu, {
		parent = mouse,
		offset = {
			x = geo.x + geo.width / 2 - mouse_coords.x,
			y = taskbar_bottom - mouse_coords.y
		},
		honor_workarea = true,
		margins = gap
	})

	-- show
	awesome.emit_signal('desktop::mask:visible', true)

	menu_client = client
	self.visible = true
end

function context_menu:hide()
	if not self.visible then return end

	menu_client = nil
	self.visible = false

	awesome.emit_signal('desktop::mask:visible', false)
end

function context_menu:toggle(client)
	if context_menu.visible and client == menu_client then
		self:hide()
	else
		self:show(client)
	end
end

context_menu.buttons = {
	awful.button({ }, 1, nil, function () context_menu:hide() end)
}

local left_down = false

local function swipe_for_context_menu(widget, client)
	widget:connect_signal('mouse::leave', function ()
		if not left_down then return end

		left_down = false
		context_menu:toggle(client)
	end)
end

awesome.connect_signal(
	'desktop::mask:dismissed',
	function () context_menu:hide() end)

-- create task list

local task_list_buttons = {
	awful.button(
		{ },
		awful.button.names.LEFT,
		function () left_down = true end,
		function (c)
			left_down = false

			-- dismiss context menu
			if context_menu.visible then
				context_menu:hide()
				return
			end

			-- toggle client
			if c == client.focus then
				c.minimized = true
			else
				c:activate { raise = true }
			end
		end
	),
	awful.button(
		{ },
		awful.button.names.RIGHT,
		function (c) context_menu:toggle(c) end
	)
}

local create_task_list = function (s)
	-- https://awesomewm.org/apidoc/widgets/awful.widget.tasklist.html
	return awful.widget.tasklist {
		screen = s,
		filter = awful.widget.tasklist.filter.allscreen,
		source = function ()
			-- reverse order
			local source = { }
			local clients = client.get()

			for i = #clients, 1, -1 do
				table.insert(source, clients[i])
			end

			return source
		end,
		buttons = task_list_buttons,
		layout = {
			layout = wibox.layout.flex.horizontal,
			spacing = gap
		},
		widget_template = {
			layout = wibox.layout.align.vertical,
			{
				widget = wibox.container.background,
				id = 'background_role',
				forced_height = 2,
				wibox.widget.base.make_widget()
			},
			{
				widget  = wibox.container.margin,
				top = gap,
				bottom = gap,
				left = 2 * gap,
				right = 2 * gap,
				{
					id = 'item',
					layout = wibox.layout.fixed.horizontal,
					spacing = 2 * gap,
					{
						widget = wibox.widget.imagebox,
						id = 'icon_role'
					},
					{
						widget = wibox.container.constraint,
						strategy = 'max',
						width = max_text_width,
						{
							widget = wibox.widget.textbox,
							id = 'text_role',
							ellipsize = 'end'
						}
					},
				}
			},
			nil,
			create_callback = function (self, c --[[ , index, clients ]])
				-- assign per instance styles
				widgets.clickable.connect_signals(self)

				-- context menu
				swipe_for_context_menu(self, c)

				-- tooltip
				add_tooltip(self, c)
			end
		}
	}
end

-- this makes sure the tooltip is dismissed
-- when the taskbar is hidden or a fullscreen client is shown
awesome.connect_signal(
	'desktop::taskbar:event',
	function (taskbar)
		if taskbar.visible then return end

		timers.set_timeout(
			function ()
				if task_list_tooltip.visible then task_list_tooltip.visible = false end
			end,
			1)
	end)

--
return {
	create_task_list = create_task_list
}
