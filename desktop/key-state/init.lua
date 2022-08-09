local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local dpi = beautiful.xresources.apply_dpi
local icons = require('config.theme.icons')

local stylesheet = beautiful.icon_stylesheet
local margins = beautiful.margins

--

local caps_lock_icon = wibox.widget
{
	{
		image = icons.caps_lock,
		stylesheet = stylesheet,
		resize = true,
		widget = wibox.widget.imagebox
	},
	layout = wibox.container.margin,
	margins = margins
}

local num_lock_icon = wibox.widget
{
	{
		image = icons.num_lock,
		stylesheet = stylesheet,
		resize = true,
		widget = wibox.widget.imagebox
	},
	layout = wibox.container.margin,
	margins = margins
}

local scroll_lock_icon = wibox.widget
{
	{
		image = icons.scroll_lock,
		stylesheet = stylesheet,
		resize = true,
		widget = wibox.widget.imagebox
	},
	layout = wibox.container.margin,
	margins = margins
}

local key_state_widget = wibox.widget
{
	layout = wibox.layout.align.horizontal,
	caps_lock_icon,
	num_lock_icon,
	scroll_lock_icon
}

--- set key state
---@param key 'CAPS'|'NUM'|'SCROLL'
---@param is_visible boolean
local function set_key_state(key, is_visible)
	-- get key widget
	local widget = nil

	if key == 'CAPS' then
		widget = caps_lock_icon
	elseif key == 'NUM' then
		widget = num_lock_icon
	elseif key == 'SCROLL' then
		widget = scroll_lock_icon
	else
		return
	end

	-- show/hide widget
	if type(is_visible) == 'boolean' then
		widget.visible = is_visible
	else
		widget.visible = not widget.visible
	end
end

-- get key states
local function set_key_states()
	awful.spawn.easy_async_with_shell(
		-- wait for state to apply
		'sleep 1s && xset q | grep -Po "(Caps|Num|Scroll) Lock:\\s+\\w+"',
		function (stdout)
			local caps   = string.match(stdout, 'Caps Lock:%s+(%a+)')
			local num    = string.match(stdout, 'Num Lock:%s+(%a+)')
			local scroll = string.match(stdout, 'Scroll Lock:%s+(%a+)')

			set_key_state('CAPS',   (caps   == 'on'))
			set_key_state('NUM',    (num    == 'on'))
			set_key_state('SCROLL', (scroll == 'on'))
		end
	)
end

-- signals

awesome.connect_signal('desktop::key-state', set_key_states)

--
set_key_states()

-- limit key state to primary screen
--return awful.widget.only_on_screen(key_state_widget, 'primary')
return key_state_widget
