local awful = require('awful')

local monitor = { }

---Monitors a process with callbacks.
---@see [awful.spawn.with_line_callback](/usr/share/awesome/lib/awful/spawn.lua#with_line_callback)
---@param command string
---@param callbacks {stdout:fun(line:string),stderr:fun(line:string),output_done:function,exit:fun(reason:string,code:number)}
function monitor.create(command, callbacks)
	local m = { pid = nil }

	function m:start()
		self.pid = awful.spawn.with_line_callback(command, callbacks)
		awesome.connect_signal('exit', function () self:stop() end)
	end

	function m:stop()
		if not tonumber(self.pid) then return end
		awful.spawn(string.format('kill %s', self.pid))
	end

	return m
end

---Starts a process monitor with callbacks.
---@see [awful.spawn.with_line_callback](/usr/share/awesome/lib/awful/spawn.lua#with_line_callback)
---@param command string
---@param callbacks {stdout:fun(line:string),stderr:fun(line:string),output_done:function,exit:fun(reason:string,code:number)}
function monitor.start(command, callbacks)
	local m = monitor.create(command, callbacks)

	m:start()

	return m
end

--
return monitor
