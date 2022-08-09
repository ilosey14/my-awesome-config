local config = require('lib.config')

local settings = config.load('desktop.do-not-disturb.settings')

local do_not_disturb = (type(settings.initial_state) == 'boolean')
	and settings.initial_state
	or false

awesome.connect_signal(
	'desktop::do-not-disturb',
	function (force)
		if type(force) == 'boolean' then
			do_not_disturb = force
		else
			do_not_disturb = not do_not_disturb
		end

		-- broadcast change
		awesome.emit_signal('desktop::do-not-disturb:event', do_not_disturb)
	end)

awesome.connect_signal(
	'desktop::do-not-disturb:get',
	function () return do_not_disturb end)

return {
	create_button = require('desktop.do-not-disturb.create-button')
}
