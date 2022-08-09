local beautiful = require('beautiful')

local config = require('lib.config')
local logger = require('lib.logger')
local user = require('lib.user')

local icons = { }
local icon_dir = user.get_value('config_dir') .. 'config/theme/icons'
local icon_theme = beautiful.icon_theme

-- load icon theme table config

local cache = { }
local icon_theme_table, err = config.load(string.format('config.theme.icons.%s', icon_theme))

if not icon_theme_table then
	logger.error('[config.theme.icons] Error loading icon theme "%s" config: %s', icon_theme, err)
	icon_theme_table = { }
end

local icon_theme_path = string.format('%s/%s/%%s.svg', icon_dir, icon_theme)
local icon_default_path = string.format('%s/%%s.svg', icon_dir)

-- helper functions

local function file_exists(filename)
	local f = io.open(filename, 'r')

	if f ~= nil then
		io.close(f)
		return true
	end

	return false
end

local function cache_icon(name)
	if not name then return nil end

	-- check for theme icon
	local theme_icon = string.format(
		icon_theme_path,
		icon_theme_table[name] or name)

	if file_exists(theme_icon) then
		cache[name] = theme_icon
		return theme_icon
	end

	-- otherwise use default path
	theme_icon = string.format(
		icon_default_path,
		icon_theme_table[name] or name)
	cache[name] = theme_icon

	return file_exists(theme_icon)
		and theme_icon
		or string.format(
			icon_default_path,
			'not-found')
end

-- set up icons metatable

local mt = {
	---@param self any
	---@param name string
	---@return string?
	__index = function (self, name)
		return cache[name] or cache_icon(name)
	end
}

setmetatable(icons, mt)

--
return icons
