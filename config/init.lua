local awful = require('awful')

awful.util.shell = 'sh'

-- in order
require('config.theme')
require('config.global')
require('config.client')
require('config.tags')

awesome.connect_signal(
	'startup',
	function () require('config.auto-start') end)
