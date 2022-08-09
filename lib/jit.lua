local logger = require('lib.logger')

---Just-In-Time loading module.
local jit = { mod_table = { } }

---Gets a JIT module state table by name.
---@param mod_name string
---@return table
function jit:get_mod(mod_name)
	if self.mod_table[mod_name] == nil then
		self.mod_table[mod_name] = {
			is_loaded = false,
			did_error = false,
			target = nil
		}
	end

	return self.mod_table[mod_name]
end

---Loads a module and returns its state or `nil` on error.
---@param mod_name string
---@return table?
---@return boolean? err
function jit:load(mod_name)
	local mod = self:get_mod(mod_name)

	if not mod.is_loaded then
		if mod.did_error then return end

		local start_time = os.time()

		if not xpcall(
			function () mod.target = require(mod_name) end,
			function (msg) logger.error('JIT error loading "%s".\n%s', mod_name, msg) end)
		then
			mod.did_error = true
			return nil, true
		end

		logger.log(
			'JIT loaded "%s" in approx. %i sec.',
			mod_name,
			os.time() - start_time)
		mod.is_loaded = true
	end

	return mod.target
end

---Registers a module to be JIT loaded.
---Any module `"type.name"` will be loaded via the signal `"type::name"`.
---@param mod_name string
function jit:init(mod_name)
	local signal = string.gsub(mod_name, '%.', '::', 1)

	local function invoke(...)
		local _, err = self:load(mod_name)

		-- remove jit loader and call module
		if not err then
			awesome.disconnect_signal(signal, invoke)
			awesome.emit_signal(signal, ...)
		end
	end

	awesome.connect_signal(signal, invoke)
end

return jit
