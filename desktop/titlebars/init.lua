local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local config = require('lib.config')
local timers = require('lib.timers')

local dpi = beautiful.xresources.apply_dpi
local settings = config.load(
	'desktop.titlebars.settings',
	{
		beautiful = beautiful,
		dpi = dpi
	})

local dblclick_timeout = settings.dblclick_timeout
local default_position = settings.position
local default_size = settings.size
local default_background = settings.background
local default_has_title = settings.has_title
local margins = beautiful.margins
local spacing = settings.spacing
local filter_table = settings.filters

awful.titlebar.enable_tooltip = settings.enable_tooltip
awful.titlebar.fallback_name  = settings.fallback_name

-- event handlers

local is_dbl_active = false
local dblclick_handler = function (callback)
	if is_dbl_active then
		is_dbl_active = false -- prevent triple-click calling dblclick twice
		callback()
		return
	end

	is_dbl_active = true

	timers.set_timeout(
		function () is_dbl_active = false end,
		dblclick_timeout)
end

local create_click_events = function (c)
	local buttons = {
		awful.button(
			{ },
			1,
			function ()
				dblclick_handler(function ()
					c.maximized = not c.maximized
					c:raise()
				end)
				c:activate { context = 'titlebar', action = 'mouse_move'}
			end
		),
		awful.button(
			{ },
			3,
			function ()
				c:activate { context = 'titlebar', action = 'mouse_resize'}
			end
		)
	}

	return buttons
end

-- compile filters

local filters = { }
local filter_operations = {
	_eq = function (a, b) return a == b end,
	_ne = function (a, b) return a ~= b end,
	_lt = function (a, b) return a < b end,
	_le = function (a, b) return a <= b end,
	_gt = function (a, b) return a > b end,
	_ge = function (a, b) return a >= b end,
	_in = function (a, b)
		for _, value in ipairs(b) do
			if a == value then return true end
		end

		return false
	end
}

for _, filter in ipairs(filter_table) do
	local profile = {
		filter = { },
		args = { }
	}

	-- separate filter and profile args
	for name, arg in pairs(filter) do
		if type(name) == 'number' then
			-- compare each target key against its conditions
			for key, conditions in pairs(arg) do
				profile.filter[key] = { }

				-- multiple conditions for each target key
				for op, value in pairs(conditions) do
					-- find comparison function from table
					local comparer = filter_operations[op]

					if comparer ~= nil then
						table.insert(profile.filter[key], function (v) return comparer(v, value) end)
					end
				end
			end
		else
			profile.args[name] = arg
		end
	end

	table.insert(filters, profile)
end

---Match a target object to a profile filter
---@param target table
---@return table?
local function get_titlebar_profile(target)
	if type(target) ~= 'client' then return nil end

	for _, profile in ipairs(filters) do
		-- compare each target key from `filter` against its conditions
		for key, comparers in pairs(profile.filter) do
			local success = true

			for _, comparer in ipairs(comparers) do
				-- entire match is false if any comparison does not succeed
				local result = comparer(target[key])

				if not result then
					success = false
					break
				end
			end

			-- all comparisons succeeded
			if success then
				return profile.args
			end
		end
	end

	-- there were no profiles where all comparisons succeeded
	return nil
end

--

---@param c any
---@param args? {position:string,size:number,background:string,has_title:boolean}
local create_titlebar = function (c, args)
	if not args then args = { } end

	local position = args.position
	local size = args.size or default_size
	local background = args.background or default_background
	local has_title = args.has_title or default_has_title

	-- button visibility
	if not args.buttons then args.buttons = { } end

	local close_button = (args.buttons.close ~= false) and awful.titlebar.widget.closebutton(c) or nil
	local maximize_button = (args.buttons.maximize ~= false) and awful.titlebar.widget.maximizedbutton(c) or nil
	local minimize_button = (args.buttons.minimize ~= false) and awful.titlebar.widget.minimizebutton(c) or nil
	local ontop_button = (args.buttons.ontop ~= false) and awful.titlebar.widget.ontopbutton(c) or nil
	local floating_button = (args.buttons.floating ~= false) and awful.titlebar.widget.floatingbutton(c) or nil

	-- verify position
	local orientation = nil

	if  position ~= 'top' and
		position ~= 'bottom' and
		position ~= 'left' and
		position ~= 'right'
	then
		position = default_position
	end

	if position == 'top' or position == 'bottom' then
		orientation = 'horizontal'
	else
		orientation = 'vertical'
	end

	-- match title orientation
	local title_widget = nil

	if has_title ~= false then
		if orientation == 'horizontal' then
			title_widget = awful.titlebar.widget.titlewidget(c)
		else
			title_widget = wibox.container.rotate(
				awful.titlebar.widget.titlewidget(c),
				(position == 'left') and 'east' or 'west')
		end
	end

	-- create titlebar
	local titlebar = awful.titlebar(c, {
		position = position,
		bg = background,
		size = size
	})
	local top_right = wibox.widget {
		{
			close_button,
			maximize_button,
			minimize_button,
			spacing = spacing,
			layout  = wibox.layout.fixed[orientation]
		},
		margins = margins,
		widget = wibox.container.margin
	}
	local middle_center = wibox.widget {
		nil,
		title_widget,
		nil,
		buttons = create_click_events(c),
		expand = 'none',
		layout = wibox.layout.align[orientation]
	}
	local bottom_left = wibox.widget {
		{
			ontop_button,
			floating_button,
			spacing = spacing,
			layout  = wibox.layout.fixed[orientation]
		},
		margins = margins,
		widget = wibox.container.margin
	}

	if orientation == 'horizontal' then
		titlebar:setup {
			bottom_left,
			middle_center,
			top_right,
			layout = wibox.layout.align[orientation]
		}
	else
		titlebar:setup {
			top_right,
			middle_center,
			bottom_left,
			layout = wibox.layout.align[orientation]
		}
	end
end

--

local profiles = { }

client.connect_signal(
	'request::manage',
	function (c)
		local args = get_titlebar_profile(c)

		if c.window then
			profiles[c.window] = args
		end
	end)

client.connect_signal(
	'request::unmanage',
	function (c) profiles[c.window] = nil end)

client.connect_signal(
	'request::titlebars',
	function (c)
		local profile = profiles[c.window]

		if profile then
			create_titlebar(c, profile)
			return
		end

		-- no profile matched client, use defaults
		create_titlebar(c)
	end)

client.connect_signal(
	'titlebar:visible',
	function (c, is_visible)
		if not c then return end

		local profile = profiles[c.window]
		local position = profile and profile.position or default_position

		if type(is_visible) == 'boolean' then
			if is_visible then
				awful.titlebar.show(c, position)
			else
				awful.titlebar.hide(c, position)
			end
		else
			awful.titlebar.toggle(c, position)
		end
	end)
