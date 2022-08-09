local awful = require('awful')
local naughty = require('naughty')

local config = require('lib.config')
local icons = require('config.theme.icons')
local monitor = require('lib.monitor')

local settings = config.load('desktop.airplane-mode.settings')

--

local devices = { }
local device_filter = settings.device_filter or { }
local is_airplane_mode = (settings.initial_state == 'on')

---@param block boolean
local function block_devices(block)
	local action = block and 'block' or 'unblock'
	local cmd = { }

	for i, _ in pairs(devices) do
		table.insert(cmd, string.format('rfkill %s %s', action, i))
	end

	if #cmd == 0 then return end

	awful.spawn.with_shell(table.concat(cmd, ';'))
end

-- monitor

local airplane_monitor = monitor.create(
	'rfkill event',
	{
		stdout = function (line)
			local id, _, _, soft, hard =
				string.match(line, 'idx%s+(%d+)%s+type%s+(%d+)%s+op%s+(%d+)%s+soft%s+(%d+)%s+hard%s+(%d+)')
			local device = devices[id]

			if not device then return end

			device.soft_blocked = (soft == '1')
			device.hard_blocked = (hard == '1')

			-- broadcast event
			awesome.emit_signal('desktop::airplane-mode:event', device)
		end,
		exit = function (reason, code)
			naughty.notification {
				title = 'Airplane-Mode Monitoring Interrupted',
				message = string.format('Reason: "%s"\nCodeOrSignal: "%s"', reason, code),
				icon = icons.airplane_mode
			}
		end
	})

-- get device indices

awful.spawn.easy_async(
	'rfkill -r',
	function (stdout)
		local device_count = 0

		for id, type, device, soft, hard in
			string.gmatch(stdout, '(%d+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)\n')
		do
			-- filter
			local is_valid = false

			for _, filter in ipairs(device_filter) do
				if filter == type then
					is_valid = true
					break
				end
			end

			-- add device
			if is_valid then
				devices[id] = {
					type = type,
					device = device,
					soft_blocked = (soft == 'blocked'),
					hard_blocked = (hard == 'blocked')
				}
				device_count = device_count + 1
			end
		end

		-- disable button if nothing found
		if device_count == 0 then
			awesome.emit_signal('desktop::airplane-mode:event', nil)
			airplane_monitor = nil
			return
		end

		-- set initial state
		airplane_monitor:start()

		if is_airplane_mode then
			block_devices(true)
		end
	end)

-- signals

awesome.connect_signal(
	'desktop::airplane-mode',
	function (on)
		if type(on) ~= 'boolean' then on = not is_airplane_mode end

		is_airplane_mode = on
		block_devices(is_airplane_mode)
	end)

awesome.connect_signal(
	'desktop::airplane-mode:get',
	function () return is_airplane_mode end)

--
return {
	create_button = require('desktop.airplane-mode.create-button')
}
