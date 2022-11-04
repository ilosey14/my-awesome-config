local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local wibox = require('wibox')

local history = require('desktop.switcher.history')
local mod = require('config.global.mod')
local timers = require('lib.timers')
local user = require('lib.user')
local widgets = require('widgets')

local dpi = beautiful.xresources.apply_dpi

local gap = beautiful.useless_gap
local geo = screen.primary.geometry
local margins = beautiful.margins
local item_size = dpi((geo.width or 1920) / 10)
local content_height = item_size * geo.height / geo.width
local image_path = string.format('%s/client-%%i.png', user.get_value('tmp_dir'))
local last_update = 0
local update_timeout = 5 * 60

--

---@param c any
---@return string
local function get_client_screenshot_path(c)
	return string.format(image_path, c.window)
end

---@param c any client
---@return string path to screenshot
local function screenshot_client(c)
	local path = get_client_screenshot_path(c)

	gears.surface(c.content):write_to_png(path)

	return path
end

local tasklist = awful.widget.tasklist {
	screen = screen.primary,
	filter = awful.widget.tasklist.filter.allscreen,
	source = history.get_client_list,
	style = {
		shape = beautiful.shapes.rounded_rect
	},
	layout = {
		layout = wibox.layout.grid.vertical,
		spacing = beautiful.useless_gap,
		forced_num_cols = 6,
		homogeneous = false
	},
	widget_template = {
		{
			{
				{
					{
						layout = wibox.layout.fixed.vertical,
						spacing = gap,

						{
							id = 'content_role',
							resize = true,
							halign = 'center',
							forced_height = content_height,
							clip_shape = beautiful.shapes.rounded_rect,
							widget = wibox.widget.imagebox
						},
						{
							layout = wibox.layout.fixed.horizontal,
							spacing = gap,

							awful.widget.clienticon,
							{
								id = 'text_role',
								ellipsize = 'end',
								widget = wibox.widget.textbox
							}
						}
					},
					width = item_size,
					height = item_size,
					strategy = 'exact',
					widget = wibox.container.constraint
				},
				margins = margins,
				widget = wibox.container.margin
			},
			id = 'background_role',
			widget = wibox.container.background
		},
		widget = widgets.clickable,
		create_callback = function (self, c)
			-- adding tasklist buttons and using a keygrabber doesn't
			-- work well together so connect button press signal here
			self:connect_signal(
				'button::press',
				function ()
						c:activate { raise = true }
						awesome.emit_signal('desktop::switcher:visible', false)
				end)

			-- set up screenshot image
			local content = self:get_children_by_id('content_role')[1];

			if not content then return end

			timers.set_timeout(function () if c.valid then content.image = screenshot_client(c) end end, 1)
		end,
		update_callback = function (self, c)
			local time = os.time()

			if time - last_update < update_timeout then return end

			last_update = time

			-- update the switcher screenshot
			if c.valid then screenshot_client(c) end
			self:emit_signal('widget::redraw_needed')
		end
	}
}

-- https://awesomewm.org/apidoc/widgets/awful.widget.tasklist.html
local switcher = awful.popup {
	widget = tasklist,
	type = 'popup_menu',
	visible = false,
	ontop = true,
	maximum_width = screen.primary.geometry.width,
	maximum_height = screen.primary.geometry.height,
	minimum_width = item_size,
	minimum_height = item_size,
	bg = beautiful.primary,
	placement = awful.placement.centered,
	shape = beautiful.shapes.rounded_rect
}

local function hide_switcher()
	-- hide and reset
	switcher.visible = false

	history.enable_tracking()
end

-- https://awesomewm.org/apidoc/core_components/awful.keygrabber.html
local switcher_keygrabber = awful.keygrabber {
	keybindings = {
		awful.key {
			modifiers = { mod.alt },
			key = 'Tab',
			on_press = function () history.focus_previous() end
		},
		awful.key {
			modifiers = { mod.alt, mod.shift },
			key = 'Tab',
			on_press = function () history.focus_next() end
		},
		awful.key {
			modifiers = { mod.alt },
			key = 'Right',
			on_press = function () history.focus_previous() end
		},
		awful.key {
			modifiers = { mod.alt },
			key = 'Left',
			on_press = function () history.focus_next() end
		},
		awful.key {
			modifiers = { mod.alt },
			key = 'Escape',
			on_press = function () hide_switcher() end
		},
		awful.key {
			modifiers = { },
			key = 'Escape',
			on_press = function () hide_switcher() end
		}
	},
	stop_key = mod.alt,
	stop_event = 'release',
	stop_callback = function () hide_switcher() end
}

local function show_switcher()
	if switcher.visible then return end

	history.disable_tracking()
	switcher_keygrabber:start()

	switcher.visible = true
end

-- signals
-- timeouts are needed for client activation to work reliably

awesome.connect_signal(
	'desktop::switcher:previous',
	function (s)
		show_switcher(s)
		timers.set_timeout(function () history.focus_previous() end)
	end)

awesome.connect_signal(
	'desktop::switcher:next',
	function (s)
		show_switcher(s)
		timers.set_timeout(function () history.focus_next() end)
	end)

awesome.connect_signal(
	'desktop::switcher:visible',
	function (is_visible)
		if type(is_visible) ~= 'boolean' then
			is_visible = not switcher.visible
		end

		if is_visible then
			show_switcher()
		else
			hide_switcher()
		end
	end)

client.connect_signal(
	'request::unmanage',
	function (c)
		local path = get_client_screenshot_path(c)
		awful.spawn(string.format('[[ -f "%s" ]] && rm "%s"', path, path))
	end)
