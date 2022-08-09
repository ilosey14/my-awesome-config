local awful = require('awful')
local beautiful = require('beautiful')
local ruled = require('ruled')

local client_buttons = require('config.client.buttons')
local client_keys = require('config.client.keys')
local client_shape = beautiful.shapes[beautiful.client_shape]

-- [ruled.client](https://awesomewm.org/apidoc/declarative_rules/ruled.client.html#rule)
-- [client.properties](https://awesomewm.org/apidoc/core_components/client.html#)

ruled.client.connect_signal(
	'request::rules',
	function ()
		-- all clients
		ruled.client.append_rule {
			id = 'global',
			rule = { },
			properties = {
				focus = awful.client.focus.filter,
				raise = true,
				floating = false,
				maximized = false,
				above = false,
				below = false,
				ontop = false,
				sticky = false,
				maximized_horizontal = false,
				maximized_vertical = false,
				keys = client_keys,
				buttons = client_buttons,
				titlebars_enabled = false,
				placement = awful.placement.centered + awful.placement.no_offscreen,
				shape = client_shape,
				screen = mouse.screen, --awful.screen.preferred,
			}
		}

		-- dialogs
		ruled.client.append_rule {
			id = 'dialog',
			rule_any = {
				type = { 'dialog' },
			},
			properties = {
				floating = true,
				above = true,
				skip_taskbar = true
			}
		}

		-- utilities
		ruled.client.append_rule {
			id = 'utility',
			rule_any = {
				type = { 'utility' }
			},
			properties = {
				floating = true
			}
		}

		-- splash screens
		ruled.client.append_rule {
			id = 'splash',
			rule_any = {
				type = { 'splash' }
			},
			properties = {
				floating = true,
				above = true,
				skip_taskbar = true
			}
		}

		-- notifications
		ruled.client.append_rule {
			id = 'notification',
			rule_any = {
				type = { 'notification' }
			},
			properties = {
				ontop = true
			}
		}
	end
)