-- add pam path to cpath
package.cpath = package.cpath .. ';/usr/lib/lua-pam/?.so;'

local pam = require('liblua_pam') -- aur/lua-pam-git
local fs = require('gears.filesystem')

local user = { }

---Authenticates user password
---@param password string
---@return boolean
function user.authenticate(password)
	return pam.auth_current_user(password)
end

-- get user values

local config_dir = fs.get_configuration_dir()
local values = {
	config_dir = config_dir,
	host = awesome.hostname,
	name = os.getenv('USER'),
	image = string.format('%s/config/user/image.jpg', config_dir),
	tmp_dir = string.format('%s/tmp', config_dir)
}

---Gets a value
---@param key 'name'|'host'|'config_dir'|'image'|'tmp_dir'
---@return string
function user.get_value(key)
	return values[key]
end

--

---Gets formatted string of user values.
---Place values inline via `%{value}`.
---
---```lua
---value = 'config_dir'|'host'|'name'|'tmp_dir'
---```
---@param format string
---@return string
---@return number count
function user.format(format)
	return string.gsub(
		format,
		'%%%b{}',
		function (name) return values[string.sub(name, 3, -2)] end)
end

return user
