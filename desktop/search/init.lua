-- TODO create search bar and search logic

awesome.connect_signal(
	'desktop::search',
	function ()
		awesome.emit_signal('desktop::mask:visible', false)
		--
	end)

--
return {
	create_button = require('desktop.search.create-button')
}
