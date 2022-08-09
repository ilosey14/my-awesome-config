local beautiful = require('beautiful')
local wibox = require('wibox')

local timers = require('lib.timers')

local clickable = { }

---@param widget any
---@param cursor string?
function clickable.connect_signals(widget, cursor)
	local widget_wibox, cursor_default, bg_default, timeout

	if type(cursor) ~= 'string' then cursor = beautiful.cursor_pointer end

	widget:connect_signal(
		'mouse::enter',
		function ()
			bg_default = widget.bg
			widget.bg = beautiful.bg_hover

			local w = mouse.current_wibox

			if w then
				cursor_default = w.cursor
				widget_wibox = w
				w.cursor = cursor
			end

			timeout = timers.set_timeout(
				function () widget.bg = bg_default end,
				5)
		end)

	widget:connect_signal(
		'mouse::leave',
		function ()
			widget.bg = bg_default

			if widget_wibox then
				widget_wibox.cursor = cursor_default
				widget_wibox = nil
			end

			if timeout then
				timeout:stop()
				timeout = nil
			end
		end)

	widget:connect_signal(
		'button::press',
		function ()
			widget.bg = beautiful.bg_press

			if timeout then
				timeout:stop()
				timeout = nil
			end

			timeout = timers.set_timeout(
				function () widget.bg = bg_default end,
				3)
		end)

	widget:connect_signal(
		'button::release',
		function ()
			if timeout then
				timeout:stop()
				timeout = nil
			end

			timers.set_timeout(
				function () widget.bg = bg_default end,
				0.1)
		end)
end

local make_clickable = function (self, widget)

	local container = wibox.widget {
		widget,
		widget = wibox.container.background
	}

	self.connect_signals(container)

	return container
end

return setmetatable(clickable, { __call = make_clickable })
