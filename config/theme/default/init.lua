local gears = require('gears')

local user = require('lib.user')

---@param config table
---@return table
local function default_theme(config)
	local titlebar_theme = config.client.titlebar_theme

	local titlebar_icon_path = string.format(
		'%s/config/theme/icons/titlebar/%s/',
		user.get_value('config_dir'),
		titlebar_theme
	)

	return {
		-- close button
		titlebar_close_button_normal = titlebar_icon_path .. 'close_normal.svg',
		titlebar_close_button_focus = titlebar_icon_path .. 'close_focus.svg',

		-- maximized button
		titlebar_maximized_button_normal_inactive = titlebar_icon_path .. 'maximized_normal_inactive.svg',
		titlebar_maximized_button_focus_inactive = titlebar_icon_path .. 'maximized_focus_inactive.svg',
		titlebar_maximized_button_normal_active = titlebar_icon_path .. 'maximized_normal_active.svg',
		titlebar_maximized_button_focus_active = titlebar_icon_path .. 'maximized_focus_active.svg',

		-- minimize button
		titlebar_minimize_button_normal = titlebar_icon_path .. 'minimize_normal.svg',
		titlebar_minimize_button_focus = titlebar_icon_path .. 'minimize_focus.svg',

		-- ontop button
		titlebar_ontop_button_normal_inactive = titlebar_icon_path .. 'ontop_normal_inactive.svg',
		titlebar_ontop_button_focus_inactive = titlebar_icon_path .. 'ontop_focus_inactive.svg',
		titlebar_ontop_button_normal_active = titlebar_icon_path .. 'ontop_normal_active.svg',
		titlebar_ontop_button_focus_active = titlebar_icon_path .. 'ontop_focus_active.svg',

		-- sticky button
		titlebar_sticky_button_normal_inactive = titlebar_icon_path .. 'sticky_normal_inactive.svg',
		titlebar_sticky_button_focus_inactive = titlebar_icon_path .. 'sticky_focus_inactive.svg',
		titlebar_sticky_button_normal_active = titlebar_icon_path .. 'sticky_normal_active.svg',
		titlebar_sticky_button_focus_active = titlebar_icon_path .. 'sticky_focus_active.svg',

		-- floating button
		titlebar_floating_button_normal_inactive = titlebar_icon_path .. 'floating_normal_inactive.svg',
		titlebar_floating_button_focus_inactive = titlebar_icon_path .. 'floating_focus_inactive.svg',
		titlebar_floating_button_normal_active = titlebar_icon_path .. 'floating_normal_active.svg',
		titlebar_floating_button_focus_active = titlebar_icon_path .. 'floating_focus_active.svg',

		-- hovered close button
		titlebar_close_button_normal_hover = titlebar_icon_path .. 'close_normal_hover.svg',
		titlebar_close_button_focus_hover = titlebar_icon_path .. 'close_focus_hover.svg',

		-- hovered maximized button
		titlebar_maximized_button_normal_inactive_hover = titlebar_icon_path .. 'maximized_normal_inactive_hover.svg',
		titlebar_maximized_button_focus_inactive_hover = titlebar_icon_path .. 'maximized_focus_inactive_hover.svg',
		titlebar_maximized_button_normal_active_hover = titlebar_icon_path .. 'maximized_normal_active_hover.svg',
		titlebar_maximized_button_focus_active_hover = titlebar_icon_path .. 'maximized_focus_active_hover.svg',

		-- hovered minimize button
		titlebar_minimize_button_normal_hover = titlebar_icon_path .. 'minimize_normal_hover.svg',
		titlebar_minimize_button_focus_hover = titlebar_icon_path .. 'minimize_focus_hover.svg',

		-- hovered ontop button
		titlebar_ontop_button_normal_inactive_hover = titlebar_icon_path .. 'ontop_normal_inactive_hover.svg',
		titlebar_ontop_button_focus_inactive_hover = titlebar_icon_path .. 'ontop_focus_inactive_hover.svg',
		titlebar_ontop_button_normal_active_hover = titlebar_icon_path .. 'ontop_normal_active_hover.svg',
		titlebar_ontop_button_focus_active_hover = titlebar_icon_path .. 'ontop_focus_active_hover.svg',

		-- hovered sticky button
		titlebar_sticky_button_normal_inactive_hover = titlebar_icon_path .. 'sticky_normal_inactive_hover.svg',
		titlebar_sticky_button_focus_inactive_hover = titlebar_icon_path .. 'sticky_focus_inactive_hover.svg',
		titlebar_sticky_button_normal_active_hover = titlebar_icon_path .. 'sticky_normal_active_hover.svg',
		titlebar_sticky_button_focus_active_hover = titlebar_icon_path .. 'sticky_focus_active_hover.svg',

		-- hovered floating button
		titlebar_floating_button_normal_inactive_hover = titlebar_icon_path .. 'floating_normal_inactive_hover.svg',
		titlebar_floating_button_focus_inactive_hover = titlebar_icon_path .. 'floating_focus_inactive_hover.svg',
		titlebar_floating_button_normal_active_hover = titlebar_icon_path .. 'floating_normal_active_hover.svg',
		titlebar_floating_button_focus_active_hover = titlebar_icon_path .. 'floating_focus_active_hover.svg',

		-- client shapes
		shapes = {
			circle = function (c, w, h)
				gears.shape.circle(c, w, h)
			end,
			rectangle = function (c, w, h)
				gears.shape.rectangle(c, w, h)
			end,
			rounded_rect = function (c, w, h)
				gears.shape.rounded_rect(c, w, h, config.client.border_radius)
			end
		}
	}
end

return default_theme
