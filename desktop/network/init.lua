local awful = require('awful')
local naughty = require('naughty')

local config = require('lib.config')
local icons = require('config.theme.icons')
local monitor = require('lib.monitor')
local timers = require('lib.timers')

-- TODO provide SSID of current network
-- via `iw` i.e. `iw dev wlan0 link | grep SSID`
-- and other info e.i. rx bitrate ??
-- can replace other wifi cmds below ??

local settings = config.load('desktop.network.settings')
local network_type = {
	ethernet = 'ethernet',
	[settings.wired_interface] = 'ethernet',
	--
	wifi = 'wifi',
	[settings.wireless_interface] = 'wifi'
}
local network_state = {
	down = 'DOWN',
	up = 'UP',
	unknown = 'UNKNOWN'
}
local commands = {
	start_monitor = settings.start_monitor,
	ping = settings.ping,
	wireless_strength = settings.wireless_strength,
}

-- functions

---@param callback fun(is_connected: boolean, ping: number)
local function get_network_health(callback)
	awful.spawn.easy_async_with_shell(
		commands.ping,
		function (stdout)
			if string.match(stdout, '100%% packet loss') then
				callback(false, 0)
				return
			end

			callback(
				true,
				tonumber(string.match(stdout, 'rtt .+ = (%d+%.%d+)')) or 0)
		end
	)
end

---@see [https://askubuntu.com/](https://askubuntu.com/questions/95676/a-tool-to-measure-signal-strength-of-wireless)
---@param callback fun(percent: number)
local function get_wireless_strength(callback)
	awful.spawn.easy_async_with_shell(
		commands.wireless_strength,
		function (stdout)
			callback((tonumber(stdout) or 0) * 10 / 7)
		end)
end

---@param callback fun(network: table?)
local function get_network_interface(callback)
	awful.spawn.easy_async_with_shell(
		'ip -br a',
		function (stdout)
			-- get the active interface from settings
			for if_name, state, ip4, ip6 in string.gmatch(stdout, '(%S+)%s+(%S+)%s+(%S+)%s*(.-)\n') do
				local if_type = network_type[if_name]

				if  state == network_state.up and
					(if_type == network_type.wifi or if_type == network_type.ethernet)
				then
					callback {
						if_name = if_name,
						if_type = if_type,
						state = state,
						ip4 = ip4,
						ip6 = ip6
					}

					return
				end
			end

			-- no active interface found
			callback(nil)
		end
	)
end

---@param callback fun(network: table)
local function get_network_info(callback)
	get_network_interface(function (network)
		if network ~= nil then
			get_network_health(function (is_connected, ping)
				network.is_connected = is_connected
				network.ping = ping

				if network.if_type == network_type.wifi then
					get_wireless_strength(function (strength)
						network.strength = strength

						callback(network)
					end)
				else
					callback(network)
				end
			end)
		else
			callback({ })
		end
	end)
end

local network_monitor = monitor.create(
	commands.start_monitor,
	{
		stdout = timers.debounce(
			function ()
				get_network_info(function (network) awesome.emit_signal('desktop::network', network) end)
			end,
			1),
		-- notify if the monitor shuts down unexpectedly
		exit = function (reason, code)
			awesome.emit_signal('desktop::network', { })
			naughty.notification {
				title = 'Network Monitoring Interrupted',
				message = string.format('Reason: "%s"\nCodeOrSignal: "%s"', reason, code),
				icon = icons.network_off
			}
		end
	})

-- perform initial network check and start monitor

get_network_info(function (network)
	awesome.emit_signal('desktop::network', network)
	network_monitor:start()
end)

-- return create button function
return {
	create_button = require('desktop.network.create-button')
}
