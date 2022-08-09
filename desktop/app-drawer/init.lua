local awful = require('awful')

local apps = require('config.apps')

-- TODO load apps and create app drawer widget

local function open_app_drawer()
	awesome.emit_signal('desktop::mask:visible', false)
	awful.spawn(apps.default.appmenu, false)
end

awesome.connect_signal(
	'desktop::app-drawer',
	open_app_drawer)

-- return create button function
return {
	create_button = require('desktop.app-drawer.create-button')
}
