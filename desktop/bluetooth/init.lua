local awful = require('awful')
local naughty = require('naughty')

local config = require('lib.config')
local icons = require('config.theme.icons')
local monitor = require('lib.monitor')
local timers = require('lib.timers')

local settings = config.load('desktop.bluetooth.settings')

--

local is_on = (settings.initial_state == 'on')
local power_on_cmd = 'bluetoothctl power on'
local power_off_cmd = 'bluetoothctl power off'
local device_state_cmd = ''
local device_state_cmd_template = 'bluetoothctl show %s | grep Powered'

---@param on boolean
---@param callback fun(succeeded: boolean)
local function toggle_bluetooth(on, callback)
	awful.spawn.easy_async(
		on and power_on_cmd or power_off_cmd,
		function (stdout)
			local succeeded = true

			if not string.match(stdout, 'succeeded') then
				naughty.notification {
					title = string.format('Failed to %s bluetooth device.', on and 'enable' or 'disable'),
					message = stdout,
					icon = icons.bluetooth
				}
				succeeded = false
			end

			callback(succeeded)
		end)
end

---@param callback fun(is_on: boolean)
local function get_device_state(callback)
	if type(callback) ~= 'function' then return end

	awful.spawn.easy_async_with_shell(
	device_state_cmd,
	function (stdout)
		local is_powered = string.match(stdout, 'Powered:%s+(%w+)')

		is_on = (is_powered == 'yes')
		callback(is_on)
	end)
end

-- monitor

-- FIX this command auto-quits only when called from awesome...
local bluetooth_monitor = monitor.create(
	'bluetoothctl --monitor',
	{
		stdout = timers.debounce(
			function ()
				-- broadcast event
				get_device_state(function (on) awesome.emit_signal('desktop::bluetooth:event', on) end)
			end,
			0.3),
		exit = function (reason, code)
			awesome.emit_signal('desktop::bluetooth:event', nil)
			naughty.notification {
				title = 'Bluetooth Monitoring Interrupted',
				message = string.format('Reason: "%s"\nCodeOrSignal: "%s"', reason, code),
				icon = icons.bluetooth
			}
		end
	})

-- get initial device state

awful.spawn.easy_async_with_shell(
	'bluetoothctl list | cut -d" " -f2',
	function (stdout)
		-- initialize device state
		device_state_cmd = string.format(
			device_state_cmd_template,
			string.match(stdout, '[0-9A-F:]+') or '')

		bluetooth_monitor:start()
	end)

-- signals

awesome.connect_signal(
	'desktop::bluetooth',
	function (on)
		if type(on) ~= 'boolean' then on = not is_on end

		toggle_bluetooth(on, function (succeeded) is_on = succeeded and on or not on end)
	end)

awesome.connect_signal(
	'desktop::bluetooth:get',
	function () return is_on end)

--
return {
	create_button = require('desktop.bluetooth.create-button') -- TODO
}
