local awful = require('awful')
local beautiful = require('beautiful')

local timers = require('lib.timers')

local client_shape = beautiful.shapes[beautiful.client_shape]
local fullscreen_shape = beautiful.shapes[beautiful.client_shape_fullscreen]

local function update_client_shape(c)
	if c.fullscreen then
		c.shape = fullscreen_shape
	else
		c.shape = client_shape
	end
end

-- signal function to execute when a new client appears.
client.connect_signal(
	'request::manage',
	function (c)
		-- move to active screen via mouse location ~active client~
		--c:move_to_screen(mouse.screen)
		--c:move_to_screen(client.focus.screen)

		c:activate {
			raise = true,
			switch_to_tag = true
		}

		if awesome.startup then
			-- prevent clients from being unreachable after screen count changes.
			if  not c.size_hints.user_position and
				not c.size_hints.program_position
			then
				awful.placement.no_offscreen(c)
			end

		-- HACK maintain other client geometries when a new client appears
		else
			for _, client_ in ipairs(c.screen:get_clients()) do
				update_client_shape(client_)
			end

			return
		end

		-- update client shape
		update_client_shape(c)
	end)

client.connect_signal(
	'property::fullscreen',
	function (c) update_client_shape(c) end)

client.connect_signal(
	'property::maximized',
	function (c) update_client_shape(c) end)

client.connect_signal(
	'property::floating',
	function (c) update_client_shape(c) end)

-- maintain other client geometries when
-- this client moves on to their screen
-- (clients would otherwise lose their geometry entirely)
client.connect_signal(
	'property::screen',
	function (c)
		for _, client_ in ipairs(c.screen:get_clients()) do
			if client_.maximized then
				update_client_shape(client_)
			end
		end

		-- clients are losing focus when switching physical screens.
		-- reactivating a client w/o a timeout did not work
		timers.set_timeout(function () c:activate { raise = true } end)
	end)
