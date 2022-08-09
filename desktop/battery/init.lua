local awful = require('awful')
local naughty = require('naughty')

local config = require('lib.config')
local icons = require('config.theme.icons')
local monitor = require('lib.monitor')
local timers = require('lib.timers')

local settings = config.load('desktop.battery.settings')

-- requires=(upower)
-- ref=https://cgit.freedesktop.org/upower/tree/

local battery_percent_low = settings.battery_percent_low
local battery_percent_critical = settings.battery_percent_critical
local has_notified_low = false
local has_notified_critical = false

local commands = {
	info_filter = { 'present', 'percentage', 'icon-name' },
	get_info = 'upower -i %s | egrep "%s"',
	get_device_path = 'upower -e | grep BAT',
	start_monitor = 'upower -m'
}

-- info

local upower_key_value = '%s*([^:\n]+):%s*([^\n]+)'

---@param callback fun(info: table) table keys are camel case. "yes"/"no" converted to `boolean`.
local function get_battery_info(callback)
	awful.spawn.easy_async(
		commands.get_info,
		function (stdout)
			-- parse info
			local info = { }

			for k, v in string.gmatch(stdout, upower_key_value) do
				-- camel case
				local key = string.gsub(k, '[%s%-]', '_')
				local value = nil

				-- parse values
				if v == 'yes' then
					value = true
				elseif v == 'no' then
					value = false
				elseif key == 'icon_name' then
					-- convert upower icon names to theme icons
					-- format icon names for theme icons.conf
					value = string.gsub(
						string.match(v, '\'(.-)-symbolic\''),
						'[%s%-]',
						'_')
				else
					value = v
				end

				-- set info
				info[key] = value
			end

			-- pass info to callback
			callback(info)
		end)
end

---@param percentage number|nil
local function notify_low_battery(percentage)
	if type(percentage) ~= "number" then
		return

	-- normal
	elseif percentage > battery_percent_low then
		if has_notified_low      then has_notified_low      = false end
		if has_notified_critical then has_notified_critical = false end

	-- low
	elseif percentage > battery_percent_critical then
		if not has_notified_low then
			naughty.notification {
				title = 'Battery low',
				icon = icons.battery_low
			}
			has_notified_low = true
		end

	-- critical
	elseif not has_notified_critical then
		naughty.notification {
			title = 'Battery critically low',
			icon = icons.battery_caution,
			urgency = 'critical'
		}
		has_notified_critical = true
	end
end

-- upowerd monitor

local battery_monitor = monitor.create(
	commands.start_monitor,
	{
		-- stdout notifies that the battery state has updated
		-- and we should get updated info
		stdout = timers.debounce(
			function ()
				get_battery_info(function (battery)
					-- emit updated info
					awesome.emit_signal('desktop::battery', battery)

					-- notify if low battery
					notify_low_battery(
						tonumber(string.match(battery.percentage, '%d+')))
				end)
			end,
			1),
		-- notify if the monitor shuts down unexpectedly
		exit = function (reason, code)
			awesome.emit_signal(
				'desktop::battery',
				{
					icon_name = 'battery_caution',
					percentage = ''
				})
			naughty.notification {
				title = 'Battery Monitoring Interrupted',
				message = string.format('Reason: "%s"\nCodeOrSignal: "%s"', reason, code),
				icon = icons.battery_caution
			}
		end
	})

-- start by getting the device path to set info command
-- and perform initial battery check

awful.spawn.easy_async_with_shell(
	commands.get_device_path,
	function (stdout)
		if not stdout or #stdout == 0 then return end

		commands.get_info = string.format(
			commands.get_info,
			string.gsub(stdout, '\n', ''),
			table.concat(commands.info_filter, '|'))

		get_battery_info(function (battery)
			awesome.emit_signal('desktop::battery:visible', battery.present)
			awesome.emit_signal('desktop::battery', battery)

			if battery.present then
				battery_monitor:start()
			end
		end)
	end)

--
return {
	create_button = require('desktop.battery.create-button')
}
