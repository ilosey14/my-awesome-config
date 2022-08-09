local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')
local wibox = require('wibox')

local config = require('lib.config')
local create_meter = require('desktop.control-center.create-meter')
local icons = require('config.theme.icons')
local user = require('lib.user')
local widgets = require('widgets')

local airplane_mode = require('desktop.airplane-mode')
local do_not_disturb = require('desktop.do-not-disturb')
local exit_screen = require('desktop.exit-screen')
local bluetooth = require('desktop.bluetooth')

local dpi = beautiful.xresources.apply_dpi
local settings = config.load('desktop.control-center.settings')

local cpu_temp_cmd = settings.cpu_temp_cmd
local cpu_temp_max = settings.cpu_temp_max or 100
local is_meters_visible = false
local margins = beautiful.margins
local spacing = beautiful.spacing
local total_system_memory = settings.total_system_memory
local row_height = dpi(64)

-- create meters

local cpu_total_prev = 0
local cpu_idle_prev = 0
local cpu_usage_meter = create_meter(
	'CPU Usage',
	icons.cpu_usage,
	function (update)
		awful.spawn.easy_async(
			'grep -m1 "^cpu " /proc/stat',
			function (stdout)
				local user_, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice =
					stdout:match('(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s')

				local total = user_ + nice + system + idle + iowait + irq + softirq + steal

				local diff_idle = idle - cpu_idle_prev
				local diff_total = total - cpu_total_prev
				local diff_usage = (diff_total - diff_idle) / diff_total * 100

				cpu_total_prev = total
				cpu_idle_prev = idle

				update(diff_usage)
			end
		)
	end,
	{
		format = '%.1f',
		unit = '%'
	})

local cpu_temp_meter = create_meter(
	'CPU Temperature',
	icons.cpu_temperature,
	function (update)
		awful.spawn.easy_async(
			cpu_temp_cmd,
			function (stdout) update((tonumber(string.match(stdout, '(%d+)')) or 0) / 1000) end
		)
	end,
	{
		format = '%.1f',
		max_value = cpu_temp_max / 1000,
		min_value = 20,
		unit = '°C'
	})

local ram_usage_meter = create_meter(
	'RAM Usage',
	icons.ram_usage,
	function (update)
		awful.spawn.easy_async_with_shell(
			'free | grep -m1 ^Mem',
			function (stdout)
				-- see https://github.com/dylanaraps/neofetch/blob/master/neofetch get_memory()
				local total, used, free, shared, buff_cache, available =
					stdout:match('(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)')

				update(math.ceil((total + shared - free - buff_cache) / 1024))
			end)
	end,
	{
		max_value = total_system_memory,
		unit = 'MiB'
	})

local storage_usage_meter = create_meter(
	'Storage',
	icons.storage_usage,
	function (update)
		awful.spawn.easy_async_with_shell(
			'df -h /home | grep -m1 "^/"',
			function (stdout) update(tonumber(string.match(stdout, '(%d+)%%')) or 0) end)
	end,
	{
		format = '%.f',
		unit = '%'
	})

-- this meter only needs to be initialized to get
-- the current usage value so there will be
-- no update behavior in the meter timer
storage_usage_meter:update_async()

-- meter timer

local meter_timer = gears.timer {
	timeout = 1.5,
	callback = function ()
		cpu_usage_meter:update_async()
		cpu_temp_meter:update_async()
		ram_usage_meter:update_async()
	end
}

--
--
--

local format_item = function (widget)
	return wibox.widget {
		{
			widget,
			margins = margins,
			widget = wibox.container.margin
		},
		forced_height = row_height,
		bg = beautiful.groups_bg,
		shape = beautiful.shapes.rounded_rect,
		widget = wibox.container.background
	}
end

---@param label string
---@param icon string
---@param signal string
---@param on_change fun(new_value: number)
local function create_slider(label, icon, signal, on_change)
	local is_changing = false

	local image = wibox.widget {
		image = icon,
		stylesheet = beautiful.icon_stylesheet,
		resize = true,
		widget = wibox.widget.imagebox
	}

	local text = wibox.widget {
		text = label,
		widget = wibox.widget.textbox
	}

	local slider = wibox.widget {
		bar_shape = beautiful.shapes.rounded_rect,
		bar_height = dpi(8),
		bar_color = beautiful.secondary,
		handle_color = beautiful.accent,
		handle_shape = beautiful.shapes.circle,
		minimum = 0,
		maximum = 100,
		widget = wibox.widget.slider
	}

	-- signals

	slider:connect_signal(
		'property::value',
		function (_, new_value)
			if not is_changing then
				on_change(new_value)
			end
		end)
	awesome.connect_signal(
		signal..':event',
		function (value)
			is_changing = true
			slider.value = value
			is_changing = false
		end)

	-- initial value

	awesome.emit_signal(
		signal..':value',
		function (value)
			is_changing = true
			slider.value = value
			is_changing = false
		end)

	--
	return wibox.widget {
		layout = wibox.layout.align.vertical,
		spacing = spacing,
		text,
		{
			layout = wibox.layout.align.horizontal,
			spacing = spacing,
			image,
			slider,
			nil
		},
		nil
	}
end

---@param force boolean
local function toggle_meters(force)
	if force then
		meter_timer:start()
	else
		meter_timer:stop()
	end
end

local panel_switch_icon = wibox.widget {
	image = icons.cpu_usage,
	stylesheet = beautiful.icon_stylesheet,
	resize = true,
	widget = wibox.widget.imagebox
}

local panel_switch_button = wibox.widget {
	{
		{
			panel_switch_icon,
			margins = margins,
			widget = wibox.container.margin
		},
		widget = widgets.clickable
	},
	bg = beautiful.transparent,
	shape = beautiful.shapes.circle,
	widget = wibox.container.background
}

local vertical_separator = wibox.widget {
	orientation = 'vertical',
	forced_height = dpi(1),
	forced_width = dpi(1),
	span_ratio = 0.55,
	widget = wibox.widget.separator
}

local control_center_row_top = wibox.widget {
	layout = wibox.layout.align.horizontal,
	forced_height = dpi(48),
	nil,
	format_item {
		layout = wibox.layout.fixed.horizontal,
		spacing = spacing,
		{
			image = user.get_value('image'),
			forced_height = dpi(28),
			resize = true,
			clip_shape = function (c, w, h)
				gears.shape.rounded_rect(c, w, h, beautiful.groups_radius)
			end,
			widget = wibox.widget.imagebox
		},
		{
			text = user.format('%{name} @ %{host}'),
			font = beautiful.font,
			align = 'left',
			valign = 'center',
			widget = wibox.widget.textbox
		}
	},
	{
		format_item {
			layout = wibox.layout.fixed.horizontal,
			spacing = spacing,
			panel_switch_button,
			vertical_separator,
			exit_screen.create_button()
		},
		left = margins,
		widget = wibox.container.margin
	}
}

local main_control_row_buttons = format_item {
	layout = wibox.layout.align.horizontal,
	spacing = spacing,
	expand = 'none',
	airplane_mode.create_button(),
	bluetooth.create_button(), -- FIX
	do_not_disturb.create_button()
}

-- sliders

local brightness_old_value = nil
local volume_old_value = nil

local main_control_row_sliders = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	spacing = spacing,
	format_item(create_slider(
		'Brightness',
		icons.brightness,
		'desktop::brightness',
		function (new_value)
			if brightness_old_value then
				awesome.emit_signal('desktop::brightness', new_value - brightness_old_value, true)
			end
			brightness_old_value = new_value
		end)),
	format_item(create_slider(
		'Volume',
		icons.volume,
		'desktop::volume',
		function (new_value)
			if volume_old_value then
				awesome.emit_signal('desktop::volume', new_value - volume_old_value, true)
			end
			volume_old_value = new_value
		end))
}

-- TODO
-- change to spt status
-- need to update control center to only update
-- when shown/visible. then can get spt status `spt pb -s`
-- ! create music player util using the spotify web api and spotifyd somehow
-- ! can start/manage/stop spotifyd daemon
-- ! use `awful.spawn.with_line_callback` on spotifyd to monitor status while running
local main_control_now_playing = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	format_item {
		--require('widgets.mpd'),
		margins = margins,
		widget = wibox.container.margin
	}
}

-- TODO popup window instance
-- TODO for in-depth hardware monitoring
-- TODO with more metrics and graphs.
-- TODO ->build<- or call 3rd party app ?
local monitor_control_row_progress_bars = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	spacing = spacing,
	format_item(cpu_usage_meter),
	format_item(cpu_temp_meter),
	format_item(ram_usage_meter),
	format_item(storage_usage_meter)
}

--
-- make control center
--

-- Set the control center geometry
local panel_width = dpi(400)

local panel_main = wibox.widget {
	id = 'main_control',
	layout = wibox.layout.fixed.vertical,
	spacing = spacing,
	visible = true,
	main_control_row_buttons,
	main_control_row_sliders,
	main_control_now_playing
}

local panel_meters = wibox.widget {
	id = 'monitor_control',
	layout = wibox.layout.fixed.vertical,
	spacing = spacing,
	visible = false,
	monitor_control_row_progress_bars
}

local panel = awful.popup {
	widget = {
		{
			{
				layout = wibox.layout.fixed.vertical,
				spacing = spacing,
				control_center_row_top,
				{
					layout = wibox.layout.stack,
					panel_main,
					panel_meters
				}
			},
			margins = margins,
			widget = wibox.container.margin
		},
		id = 'control_center',
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

local set_cc_screen = function (s)
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
		})
end

-- now that control center panels are defined,
-- set panel switch functionality
panel_switch_button:buttons {
	awful.button(
		{ },
		awful.button.names.LEFT,
		nil,
		function ()
			is_meters_visible = not is_meters_visible

			-- visibility
			if is_meters_visible then
				panel_switch_icon.image = icons.control_center
			else
				panel_switch_icon.image = icons.cpu_usage
			end

			panel_main.visible = not is_meters_visible
			panel_meters.visible = is_meters_visible

			toggle_meters(is_meters_visible)
		end)
}

local open_panel = function (s)
	toggle_meters(is_meters_visible)
	set_cc_screen(s)

	awesome.emit_signal('desktop::mask:visible', true, s)
	panel.visible = true
end

local close_panel = function ()
	toggle_meters(false)

	awesome.emit_signal('desktop::mask:visible', false)
	panel.visible = false
end

-- expose functionality

local control_center = {
	is_open = false,
	screen = nil,
	panel = panel
}

---@param s any Shows on the give screen.
function control_center:show(s)
	if self.is_open then return end

	self.is_open = true
	self.screen = s or awful.screen.focused()

	open_panel(s)
end

---@param s? any When provided, hides only if open on the given screen.
function control_center:hide(s)
	if not self.is_open then return end
	if s and self.screen.index ~= s.index then return end

	self.is_open = false
	self.screen = nil

	close_panel()
end

-- signals

awesome.connect_signal(
	'desktop::control-center',
	function (is_visible, s)
		if type(is_visible) ~= 'boolean' then
			is_visible = not control_center.is_open
		end

		if is_visible then
			-- close anything else using the mask
			awesome.emit_signal('desktop::mask:visible', false)
			control_center:show(s or awful.screen.focused())
		else
			control_center:hide(s)
		end
	end)

awesome.connect_signal(
	'desktop::mask:dismissed',
	function () control_center:hide() end)

--
return {
	create_button = require('desktop.control-center.create-button')
}
