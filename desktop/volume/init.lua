local awful = require('awful')

local icons = require('config.theme.icons')

local volume_value = 0
local volume_state = 'on'

--

---@param cmd string
---@param callback? fun(volume: number, state: 'on'|'off')
local function get_value(cmd, callback)
	awful.spawn.easy_async(cmd, function (stdout)
		volume_value, volume_state = string.match(stdout, '%[(%d+)%%%] %[(%w+)%]')

		if type(callback) == 'function' then
			callback(tonumber(volume_value) or 0, volume_state)
		end
	end)
end

local function show_osd(value, state)
	local icon

	if  value <= 0 or
		state ~= 'on'
	then
		icon = icons.volume_mute
	elseif value < 50 then
		icon = icons.volume_low
	else
		icon = icons.volume_high
	end

	awesome.emit_signal(
		'desktop::osd',
		{
			icon = icon,
			label = 'Volume',
			value = value
		})
end

-- signals

awesome.connect_signal(
	'desktop::volume',
	function (delta, silent)
		local cmd

		-- make command
		if type(delta) ~= 'number' then
			return
		elseif delta > 0 then
			cmd = string.format('amixer sset Master %.f%%+', delta)
		elseif delta < 0 then
			cmd = string.format('amixer sset Master %.f%%-', -delta)
		end

		-- set volume
		get_value(cmd, function (value, state)
			show_osd(value, state)

			if not silent then
				awesome.emit_signal('desktop::volume:event', (state == 'on') and value or nil)
			end
		end)
	end)

awesome.connect_signal(
	'desktop::volume:mute',
	function (mute)
		local behavior

		if type(mute) == 'boolean' then
			behavior = mute and 'off' or 'on'
		else
			behavior = 'toggle'
		end

		get_value(
			string.format('amixer set Master 1+ %s', behavior),
			show_osd)
		awesome.emit_signal('desktop::volume:event', nil)
	end)

awesome.connect_signal(
	'desktop::volume:value',
	function (callback)
		if type(callback) == 'function' then callback(volume_value) end
	end)

awesome.connect_signal(
	'desktop::volume:state',
	function (callback)
		if type(callback) == 'function' then callback(volume_state) end
	end)

-- initial value
get_value(
	'amixer sget Master',
	function (value) awesome.emit_signal('desktop::volume:event', value) end)
