local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local widgets = require('widgets')

local margins = beautiful.margins

local function create_button(s)
	local button = wibox.widget {
		{
			awful.widget.layoutbox { screen = s },
			margins = margins,
			widget = wibox.container.margin
		},
		widget = widgets.clickable
	}

	button:add_button(awful.button(
		{ },
		1,
		function () awful.layout.inc(1) end
	))
	button:add_button(awful.button(
		{ },
		3,
		function () awful.layout.inc(-1) end
	))

	return button
end

return create_button
