local awful = require('awful')

local icons = require('config.theme.icons')

local brightness_value = 0

--

---@param callback? fun(value: number)
local function get_value(callback)
	awful.spawn.easy_async(
		'light -G',
		function (stdout)
			brightness_value = tonumber(string.match(stdout, '(%d+)')) or 0

			if type(callback) == 'function' then
				callback(brightness_value)
			end
		end)
end

-- signals

awesome.connect_signal(
	'desktop::brightness',
	function (delta, silent)
		-- set brightness
		if type(delta) ~= 'number' then
			return
		elseif delta > 0 then
			awful.spawn(string.format('light -A %.f', delta))
		elseif delta < 0 then
			awful.spawn(string.format('light -U %.f', -delta))
		end

		-- show osd
		get_value(function (value)
			local icon = (value < 50 and icons.brightness_low) or icons.brightness_high

			awesome.emit_signal(
				'desktop::osd',
				{
					icon = icon,
					label = 'Brightness',
					value = value
				})

			if not silent then
				awesome.emit_signal('desktop::brightness:event', value)
			end
		end)
	end)

awesome.connect_signal(
	'desktop::brightness:value',
	function (callback)
		if type(callback) == 'function' then callback(brightness_value) end
	end)

-- initial value
get_value(function (value) awesome.emit_signal('desktop::brightness:event', value) end)
