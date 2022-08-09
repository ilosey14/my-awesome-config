-- dependencies
-- # pacman -S qrencode rofi feh

local spawn = require('awful.spawn')

local date = require('lib.date')
local user = require('lib.user')

local config_dir = user.get_value('config_dir')

local function qrcode()
	local tmp = string.format('%s/tmp/qrcode_%s.png', config_dir, date.toisostring())

	spawn.easy_async_with_shell(
		string.format(
			'rofi -dmenu -p "QR Code Text" | qrencode -o "%s" -t PNG && feh "%s" && unlink "%s"',
			tmp, tmp, tmp),
		function () --[[ capture output ]] end)
end

awesome.connect_signal(
	'utils::qrcode',
	qrcode)
