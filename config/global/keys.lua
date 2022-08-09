local awful = require('awful')
local hotkeys_popup = require('awful.hotkeys_popup')

local apps = require('config.apps')
local config = require('lib.config')
local mod = require('config.global.mod')

local alt = mod.alt
local ctrl = mod.ctrl
local shift = mod.shift
local super = mod.super

-- start default terminal instance
local scratch_pad

function create_scratch_pad()
	awful.spawn(
		apps.default.terminal,
		{
			skip_taskbar = true,
			hidden = true,
			ontop = true
		},
		function (c) scratch_pad = c end)
end
create_scratch_pad()

awesome.connect_signal('exit', function () if scratch_pad then scratch_pad:kill() end end)

--

local global_keys = {

	-- Awesome

	awful.key {
		modifiers = { super },
		key = 'F1',
		on_press = function () hotkeys_popup.show_help(nil, screen.primary) end,
		group = 'Awesome',
		description = 'Show help'
	},
	awful.key {
		modifiers = { super, shift },
		key = 'r',
		on_press = awesome.restart,
		group = 'Awesome',
		description = 'Reload awesome'
	},

	-- Screen

	awful.key {
		modifiers = { super, shift },
		key = '1',
		on_press = function () awful.screen.focus_relative(-1) end,
		group = 'Screen',
		description = 'Focus the previous screen'
	},
	awful.key {
		modifiers = { super, shift },
		key = '2',
		on_press = function () awful.screen.focus_relative(1) end,
		group = 'Screen',
		description = 'Focus the next screen'
	},
	awful.key {
		modifiers = { super, alt },
		key = 'Left',
		on_press = awful.tag.viewprev,
		group = 'Tag',
		description = 'View previous tag'
	},
	awful.key {
		modifiers = { super, alt },
		key = 'Right',
		on_press = awful.tag.viewnext,
		group = 'Tag',
		description = 'View next tag'
	},

	-- Layout

	awful.key {
		modifiers = { super },
		key = '=',
		on_press = function () awful.incmwfact(0.05) end,
		group = 'Layout',
		description = 'Increase master width factor'
	},
	awful.key {
		modifiers = { super },
		key = '-',
		on_press = function () awful.incmwfact(-0.05) end,
		group = 'Layout',
		description = 'Decrease master width factor'
	},
	awful.key {
		modifiers = { super, shift },
		key = '=',
		on_press = function () awful.tag.incnmaster(1, nil, true) end,
		group = 'Layout',
		description = 'Increase the number of master clients'
	},
	awful.key {
		modifiers = { super, shift },
		key = '-',
		on_press = function () awful.tag.incnmaster(-1, nil, true) end,
		group = 'Layout',
		description = 'Decrease the number of master clients'
	},
	awful.key {
		modifiers = { super, ctrl },
		key = '=',
		on_press = function () awful.tag.incncol(1, nil, true) end,
		group = 'Layout',
		description = 'Increase the number of columns'
	},
	awful.key {
		modifiers = { super, ctrl },
		key = '-',
		on_press = function () awful.tag.incncol(-1, nil, true) end,
		group = 'Layout',
		description = 'Decrease the number of columns'
	},
	awful.key {
		modifiers = { super },
		key = '.',
		on_press = function () awful.layout.inc(1) end,
		group = 'Layout',
		description = 'Select next layout'
	},
	awful.key {
		modifiers = { super },
		key = ',',
		on_press = function () awful.layout.inc(-1) end,
		group = 'Layout',
		description = 'Select previous layout'
	},
	awful.key {
		modifiers = { super },
		key = 'g',
		on_press = function () awful.tag.incgap(1) end,
		group = 'Layout',
		description = 'Increase gap'
	},
	awful.key {
		modifiers = { super, shift },
		key = 'g',
		on_press = function () awful.tag.incgap(-1) end,
		group = 'Layout',
		description = 'Decrease gap'
	},

	-- Client

	awful.key {
		modifiers = { super },
		key = 'd',
		on_press = function ()
			for _, c in ipairs(client.get()) do
				c.minimized = true
			end
		end,
		group = 'Client',
		description = 'Show desktop'
	},

	-- Media

	awful.key {
		modifiers = { },
		key = 'XF86AudioPlay',
		on_press = function () awful.spawn.with_shell('spt pb -t > /dev/null') end,
		group = 'Media',
		description = 'Play/pause music'
	},
	awful.key {
		modifiers = { },
		key = 'XF86AudioStop',
		on_press = function () awful.spawn.with_shell('spt pb -t > /dev/null') end,
		group = 'Media',
		description = 'Play/pause music (`spt` does not provide a stop feature)'
	},
	awful.key {
		modifiers = { },
		key = 'XF86AudioNext',
		on_press = function () awful.spawn.with_shell('spt pb -n > /dev/null') end,
		group = 'Media',
		description = 'To next track'
	},
	awful.key {
		modifiers = { },
		key = 'XF86AudioPrev',
		on_press = function () awful.spawn.with_shell('spt pb -p > /dev/null') end,
		group = 'Media',
		description = 'To previous track'
	},
	awful.key {
		modifiers = { },
		key = 'XF86AudioMicMute',
		on_press = function () awful.spawn.with_shell('amixer set Capture toggle > /dev/null') end,
		group = 'Media',
		description = 'Mute microphone'
	},
	awful.key {
		modifiers = { super },
		key = 'XF86Display',
		group = 'Media',
		description = 'Blank the screen'
	},
	awful.key {
		modifiers = { },
		key = 'XF86WLAN',
		on_press = function () end,
		group = 'Media',
		description = 'Toggle airplane mode'
	},

	-- Utility

	awful.key {
		modifiers = { },
		key = 'Print',
		on_press = function () awful.spawn.with_shell(apps.default.full_screenshot .. ' > /dev/null') end,
		group = 'Utility',
		description = 'Full screenshot'
	},
	awful.key {
		modifiers = { super },
		key = 's',
		on_press = function () awful.spawn.with_shell(apps.default.full_screenshot .. ' > /dev/null') end,
		group = 'Utility',
		description = 'Full screenshot'
	},
	awful.key {
		modifiers = { super, shift },
		key = 's',
		on_press = function () awful.spawn.with_shell(apps.default.area_screenshot .. ' > /dev/null') end,
		group = 'Utility',
		description = 'Area screenshot'
	},
	awful.key {
		modifiers = { },
		key = 'Menu',
		on_press = function () --[[ TODO invoke right-click ]] end,
		group = 'Utility',
		description = 'Right click context menu'
	},

	-- Default apps

	awful.key {
		modifiers = { super, shift },
		key = 'Return',
		on_press = function () awful.spawn(apps.default.terminal) end,
		group = 'Launchers',
		description = 'Opens a new terminal window'
	},
	awful.key {
		modifiers = { super },
		key = 'Return',
		on_press = function ()
			if not scratch_pad then
				create_scratch_pad()
				return
			end

			if scratch_pad.hidden then scratch_pad.hidden = false end

			if scratch_pad.minimized or not scratch_pad.active then
				scratch_pad:activate { raise = true }
			else
				scratch_pad.minimized = true
			end
		end,
		group = 'Launchers',
		description = 'Toggles default terminal instance'
	},
	awful.key {
		modifiers = { super },
		key = 'e',
		on_press = function () awful.spawn(apps.default.file_manager) end,
		group = 'Launchers',
		description = 'Open default file manager'
	},
	awful.key {
		modifiers = { super },
		key = 'b',
		on_press = function () awful.spawn(apps.default.web_browser) end,
		group = 'Launchers',
		description = 'Open default web browser'
	},
	awful.key {
		modifiers = { ctrl, shift },
		key = 'Escape',
		on_press = function () awful.spawn(apps.default.system_monitor) end,
		group = 'Launchers',
		description = 'Open system monitor'
	}
}

--

-- local global_keys = { }
local mod_table = {
	Super = mod.super,
	Ctrl = mod.ctrl,
	Alt = mod.alt,
	Shift = mod.shift
}

awesome.connect_signal(
	'startup',
	function ()
		local keys = config.load('config.global.keys')

		for _, bind in ipairs(keys) do
			local key = bind.key

			if type(key) == 'string' and #key > 0 then
				local modifiers = bind.modifiers or { }
				local signal = bind.signal
				local on_press = (type(signal) == 'table')
					and function () awesome.emit_signal(table.unpack(signal)) end
					or function () awesome.emit_signal(signal) end

				-- convert friendly modifiers to awesome mod codes
				for i, m in ipairs(modifiers) do
					local tr = mod_table[m]

					if tr then modifiers[i] = tr end
				end

				-- append awful key
				table.insert(global_keys, awful.key {
					modifiers = modifiers,
					key = key,
					on_press = on_press,
					group = bind.group,
					description = bind.description
				})
			end
		end

		root.keys(global_keys)
	end)
