local gears = require('gears')

local timers = { }

---Sets a function `func` to be called after `timeout` seconds.
---@param func fun(...)
---@param timeout? number
---@param ... any `func` args
function timers.set_timeout(func, timeout, ...)
	local args = ...

	return gears.timer {
		timeout = timeout or 0.1,
		autostart = true,
		single_shot = true,
		callback = function () func(args) end
	}
end

---Sets a function `func` to be called every `timeout` seconds.
---@param func fun(...)
---@param timeout? number
function timers.set_interval(func, timeout, ...)
	local args = ...

	return gears.timer {
		timeout = timeout or 0,
		autostart = true,
		callback = function () func(args) end
	}
end

---Returns a function that will only call `func` if it has been at least `timeout` seconds since the last call.
---@param func fun(...)
---@param timeout number seconds
---@return fun(...)?
function timers.debounce(func, timeout)
	if type(func) ~= 'function' then return end

	local args = nil
	local timer = gears.timer {
		timeout = timeout or 0,
		single_shot = true,
		callback = function () func(args) end
	}

	return function (...)
		args = ...
		timer:again()
	end
end

---Returns a function that will only call `func` at a minimum interval of `timeout` seconds.
---@param func fun(...)
---@param timeout number seconds
---@return fun(...)?
function timers.throttle(func, timeout)
	if type(func) ~= 'function' then return end

	local timestamp = 0

	return function (...)
		local called = os.time()

		if called - timestamp >= timeout then
			func(...)
			timestamp = called
		end
	end
end

return timers
