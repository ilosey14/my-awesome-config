local beautiful = require('beautiful')

local taskbar = require('desktop.taskbar')

require('desktop.brightness')
require('desktop.lock-screen')
require('desktop.switcher')
require('desktop.volume')

awesome.connect_signal(
	'startup',
	function ()
		require('desktop.mask')
		require('desktop.menu') -- TODO redo
		require('desktop.osd')
		require('desktop.titlebars')
	end)

local padding = beautiful.margins

-- new desktop is created
screen.connect_signal(
	'request::desktop_decoration',
	function (s)
		s.padding = padding
		taskbar.create_taskbar(s)
	end)

---Updates the desktop layout based on a client state.
---@param c any
local function update_layout(c)
	if c == nil then return end

	local fullscreen = c.fullscreen

	awesome.emit_signal('desktop::taskbar:visible', not fullscreen or (fullscreen and c.minimized))

	if fullscreen then
		awesome.emit_signal('desktop::mask:visible', false)
	end
end

-- connect signals that affect the desktop layout

-- when a client's fullscreen property is changed
client.connect_signal(
	'property::fullscreen',
	function (c) update_layout(c) end)

-- when a fullscreen client is focused again
client.connect_signal(
	'focus',
	function (c)
		if not c.fullscreen then return end

		-- ensure fullscreen
		c.minimized = false

		update_layout(c)
	end)

-- when a fullscreen client is minimized
client.connect_signal(
	'property::minimized',
	function (c)
		if not c.fullscreen or not c.minimized then return end

		update_layout(c)
	end)

-- when a fullscreen client is closed (unmanaged)
client.connect_signal(
	'request::unmanage',
	function (c)
		if not c.fullscreen then return end

		update_layout(c)
	end)
