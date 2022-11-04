local beautiful = require('beautiful')
local wibox = require('wibox')

local config = require('lib.config')

local settings = config.load('desktop.wrap-around.settings')
local is_enabled = settings.enabled

-- inspired by this post: https://www.reddit.com/r/awesomewm/comments/4a41l3/code_for_cursor_screen_wraparound_functionality/
-- TODO support hot plugging monitors

if not is_enabled then return end

-- find the outer-most screens
local left_screen = screen.primary
local right_screen = screen.primary

for s in screen do
	if s.geometry.x < left_screen.geometry.x then
		left_screen = s
	elseif s.geometry.x > right_screen.geometry.x then
		right_screen = s
	end
end

-- add warp bars
local bar_width = 1
local ls_geo = left_screen.geometry
local rs_geo = right_screen.geometry
local ls_x = ls_geo.x + bar_width
local rs_x = rs_geo.x + rs_geo.width - bar_width - 1
local ltrHeightScale = rs_geo.height / ls_geo.height

local left_bar = wibox {
	screen = left_screen,
	width = bar_width,
	height = ls_geo.height,
	x = ls_geo.x,
	y = ls_geo.y,
	visible = true,
	ontop = true,
	bg = beautiful.transparent
}

left_bar:connect_signal(
	'mouse::enter',
	function ()
		local coords = mouse.coords()

		mouse.coords {
			x = rs_x,
			y = math.floor(ltrHeightScale * coords.y)
		}
	end)

local right_bar = wibox {
	screen = right_screen,
	width = bar_width,
	height = right_screen.geometry.height,
	x = rs_geo.x + rs_geo.width - bar_width,
	y = rs_geo.y,
	visible = true,
	ontop = true,
	bg = beautiful.transparent
}

right_bar:connect_signal(
	'mouse::enter',
	function ()
		local coords = mouse.coords()

		mouse.coords {
			x = ls_x,
			y = math.floor(coords.y / ltrHeightScale)
		}
	end)
