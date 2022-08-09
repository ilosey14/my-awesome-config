local user = require('lib.user')
local config_dir = user.get_value('config_dir')

local config = { }
local cache = { }
local ext = '.conf'

---@param value any
---@param scope? table global scope when parsing variable values
---@param ref_depth? integer the number of times a variable can reference another variable
---@return any value the parsed value
local function parse_vars(value, scope, ref_depth)
	local value_type = type(value)
	ref_depth = ref_depth or 128

	if value_type == 'string' then
		-- continue parsing until `value` has been resolved to a static value
		-- meaning if value references another variable, continue to parse
		for _ = 1, ref_depth do
			local did_parse = false
			local match = string.match(value, '^%%%{([^%}]+)%}$')

			-- check for exact match to support type switching (string var to table, function, etc)
			if match then
				did_parse = true
				value = load('return ' .. match, nil, 't', scope)()

				if type(value) ~= 'string' then
					return value
				end

			-- substitute inline matches, which must convert to strings
			else
				value = string.gsub(value, '%%%{(.-)%}', function (s)
					did_parse = true
					return tostring(load('return ' .. s, nil, 't', scope)())
				end)
			end

			-- nothing was parsed, value has been resolved
			if not did_parse then
				-- check for number
				return tonumber(value) or value
			end
		end

		-- did not parse value within ref_depth
		return error(string.format(
				'[lib.config:parse_config_value] Max config var reference depth exceeded (%s).',
				ref_depth))

	-- parse values recursively
	elseif value_type == 'table' then
		local buffer = { }

		for k, v in pairs(value) do
			buffer[k] = parse_vars(v, scope, ref_depth)
		end

		return buffer
	end

	return value
end

---@param cache_tbl table
---@param key string
---@param raw_value any
---@return any
local function set_value(cache_tbl, key, raw_value)
	if type(cache_tbl) ~= 'table' then return end
	if key == '_name' then return end

	cache_tbl.raw[key] = raw_value

	-- update scope
	cache_tbl.scope.self = cache_tbl.raw

	-- parse value
	cache_tbl.parsed[key] = parse_vars(raw_value, cache_tbl.scope)
end

local function create_handle(cache_tbl)
	return setmetatable({ }, {
		__newindex = function (self, key, value)
			set_value(cache_tbl, key, value)
		end,
		__index = function (self, key)
			return cache_tbl.parsed[key]
		end,
		__pairs = function (self)
			return next, cache_tbl.parsed, nil
		end
	})
end

---Loads a config file and returns a config handle \
---If the file could not be loaded, an empty `table` is return. \
---Config syntax is the contents of a standard lua table.
---```lua
---return { <config> }
---```
---@param name string config path
---@param scope? table global scope when parsing variable values
---@param reload? boolean whether to reload the config file from its source
---@return table h config table handle
---@return string? error_message
function config.load(name, scope, reload)
	-- check for cache
	if not reload and cache[name] then
		return cache[name].handle
	end

	-- open file
	local filename = string.gsub(name, '%.', '/')

	local path = string.format('%s%s%s', config_dir, filename, ext)
	local file, err1 = io.open(path, 'r')
local logger = require('lib.logger')
	if file == nil then
logger.log('no file for %s: %s',name,err1)
		return { }, err1
	end

	-- load config
	local loader, err2 = load(string.format('return {\n%s\n}', file:read('a')))

	-- close file
	file:close()

	if loader == nil then
logger.log('syntax error in %s: %s',name, err2)
		return { }, err2
	end

	-- parse config
	local raw_config = loader()

	if not scope then scope = { } end

	raw_config._name = name
	scope.self = raw_config

	local parsed_config = parse_vars(raw_config, scope)

	-- cache config
	local cache_tbl = {
		path = path,
		parsed = parsed_config,
		raw = raw_config,
		scope = scope,
		handle = nil
	}
	local handle = create_handle(cache_tbl) or { }

	cache_tbl.handle = handle
	cache[name] = cache_tbl

	--
	return handle
end

---Reads the specified file as a config file.
---@param filename string
---@return table config
---@return string? error_message
function config.read_file(filename)
	-- open file
	local path = string.format('%s/%s', config_dir, filename)
	local file, err1 = io.open(path, 'r')

	if file == nil then
		return { }, err1
	end

	-- load file
	local loader, err2 = load(string.format('return {\n%s\n}', file:read('a')))

	-- close file
	file:close()

	if loader == nil then
		return { }, err2
	end

	-- parse file
	return loader()
end

---Serialize a lua table to a config string.
---@param tbl table
---@param depth? number
---@return string?
function config.serialize(tbl, depth)
	if type(tbl) ~= 'table' then
		return error(string.format('Could not serialize config of type "%s".', type(tbl)))
	end
	if type(depth) ~= 'number' then depth = 1 end

	local buffer = { }

	if depth > 1 then table.insert(buffer, '{\n') end

	for key, value in pairs(tbl) do
		local key_type = type(key)
		local value_type = type(value)

		-- key
		if key_type == 'number' then
			table.insert(buffer, string.format('[%s]=', key))
		else
			table.insert(buffer, string.format('%s=', key))
		end

		-- value
		if value_type == 'table' then
			table.insert(buffer, config.serialize(value, depth + 1))
		elseif value_type == 'string' then
			table.insert(buffer, string.format('"%s"', string.gsub(value, '"', '\\"')))
		else
			table.insert(buffer, tostring(value))
		end

		table.insert(buffer, ',\n')
	end

	if depth > 1 then table.insert(buffer, '}') end

	return table.concat(buffer)
end

---Saves a loaded config handle.
---@param h table
---@return boolean? success
---@return string? error_message
---@return integer? error_code
function config.save(h)
	if not h then return false end

	local name = h._name
	local cache_tbl = cache[name]

	if not cache_tbl then
		return error(string.format('Could not save unknown config named "%s".', name))
	end

	-- open file
	local file, err = io.open(cache_tbl.path, "w")

	if file == nil then
		return false, err
	end

	-- write config
	cache_tbl.raw._name = nil
	file:write(config.serialize(cache_tbl.raw))
	cache_tbl.raw._name = name

	-- close
	return file:close()
end

--
return config
