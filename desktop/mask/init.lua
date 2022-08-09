local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

--

local mask = wibox {
	ontop = true,
	type = 'utility',
	visible = false,
	bg = beautiful.transparent
}

local function hide_mask()
	if not mask.visible then return end

	mask.visible = false
	awesome.emit_signal('desktop::mask:dismissed')
end

local function show_mask(s)
	if mask.visible then return end

	mask.screen = s or mouse.screen
	mask.x = s.geometry.x
	mask.y = s.geometry.y
	mask.width = s.geometry.width
	mask.height = s.geometry.height
	mask.visible = true
end

-- input passthrough

mask:connect_signal(
	'button::press',
	function (self, x, y, button)
		hide_mask()
		-- root.fake_input('button_press', button, x, y)
		-- root.fake_input('button_release', button, x, y)
	end)

local keygrabber = awful.keygrabber {
	stop_key = 'Escape',
	stop_callback = hide_mask
}

-- signals

awesome.connect_signal(
	'desktop::mask',
	function (s) show_mask(s or awful.screen.focused()) end)

awesome.connect_signal(
	'desktop::mask:visible',
	function (is_visible, s)
		if type(is_visible) ~= 'boolean' then
			is_visible = not mask.visible
		end

		if is_visible then
			keygrabber:start()
			show_mask(s or mouse.screen)
		else
			keygrabber:stop()
			hide_mask()
		end
	end)
