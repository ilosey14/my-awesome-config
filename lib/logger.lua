local date = require('lib.date')

local logger = { }

---Generic logger.
---@param output file*
---@param tag string
---@param msg string
local function write(output, tag, msg)
	local d = date.toisostring()
	local caller = debug.getinfo(3, 'Sl')

	output:write(
		string.format('%s [%s] %s:%d %s\n',
			d,
			tag,
			caller.short_src,
			caller.currentline,
			msg))
end

---Logs a message to the stdout.
---@param msg string
function logger.log(msg, ...)
	write(io.stdout, 'LOG', string.format(msg, ...))
end

---Logs a message to the sterr.
---@param msg string
function logger.error(msg, ...)
	local full_msg = debug.traceback(string.format(msg, ...))

	write(io.stderr, 'ERROR', full_msg)

	-- if debugging flag is on, send system notification (dbus? x?)
	--TODO
end

return logger
