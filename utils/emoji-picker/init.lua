local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local config = require('lib.config')
local logger = require('lib.logger')

local dpi = beautiful.xresources.apply_dpi
local emoji_font_size = 20
local emoji_font = string.gsub(beautiful.font, '(%d+)$', tostring(emoji_font_size))
local margins = beautiful.margins
local picker_emoji_rows = 10
local picker_emoji_cols = 0
local picker_height = dpi(1.5 * emoji_font_size * picker_emoji_rows)
local spacing = beautiful.spacing
local submenu_cols = 3

local emoji_picker

-- submenu

local button_grid = wibox.layout.grid {
	homogeneous = true,
	forced_num_cols = submenu_cols,
}
local submenu = awful.popup {
	widget = {
		{
			widget = wibox.container.margin,
			margins = margins,
			button_grid
		},
		bg = beautiful.bg_normal,
		border_color = beautiful.border_color_active,
		border_width = beautiful.border_width,
		shape = beautiful.shapes.rounded_rect,
		widget = wibox.container.background,

	},
	placement = awful.placement.centered,
	shape = beautiful.shapes.rectangle,
	type = 'popup_menu',
	visible = false,
	ontop = true,
	preferred_positions = 'top',
	offset = beautiful.margins,
	bg = beautiful.transparent,
	fg = beautiful.fg_normal
}

---@param buttons table
local function show_submenu(buttons)
	button_grid:reset()
	button_grid:add(table.unpack(buttons))
	submenu.visible = true
end

local function hide_submenu()
	submenu.visible = false
end

-- Use an indexed array -> `{ { name: string, buttons: { } }, ... }`
-- b/c named arrays are not always in the order of the items appended
local emoji_buttons = { }
local definition_file = 'emoji.txt'

local button_tooltip = awful.tooltip { delay_show = 1 }

local function button_mouseenter(self, _)
	button_tooltip.text = self.tooltip
end

local function button_click(self, _, _, button, _, _)
	if button ~= awful.button.names.LEFT then return end

	awful.spawn.easy_async_with_shell(
		string.format('echo -n "%s" | xsel -bin', self.text),
		function () emoji_picker:hide() end)
end

local function button_rightclick(self, _, _, button, _, _)
	if button ~= awful.button.names.RIGHT then return end
	if not self.variants then return end

	show_submenu(self.variants)
end

---Makes a new emoji button
---@param value string
---@param tooltip string
local function make_emoji_button(value, tooltip)
	local button = wibox.widget.textbox(value)

	button.font = emoji_font
	button.tooltip = tooltip

	button:connect_signal('button::press', button_click)
	button:connect_signal('mouse::enter', button_mouseenter)

	button_tooltip:add_to_object(button)

	return button
end


--
-- parse definition file
--

local emojis = config.read_file('utils/emoji-picker/' .. definition_file)

for _, group in ipairs(emojis) do
	local buttons = { }

	for _, emoji in ipairs(group) do
		local button = make_emoji_button(emoji[1], emoji[2])

		-- check for variant
		if emoji[3] then
			local base_button = buttons[#buttons]

			if not base_button.variants then
				base_button.variants = { }
				base_button:connect_signal('button::press', button_rightclick)
			end

			table.insert(base_button.variants, button)

		-- append button
		else
			table.insert(buttons, button)
		end
	end

	if #buttons > 0 then
		table.insert(emoji_buttons, {
			name = group.name or '?',
			buttons = buttons
		})
	end
end

picker_emoji_cols = #emoji_buttons

if picker_emoji_cols <= 0 then
	logger.error('[emoji-picker:init] ERROR could not parse file.')
	return
end

--
-- make picker
--

-- search bar
local search_bar_text = wibox.widget.textbox()
local search_bar = {
	layout = wibox.layout.fixed.horizontal,
	wibox.widget.textbox('🔎    '),
	search_bar_text
}
local search_bar_keygrabber = awful.keygrabber {
	keybindings = {
		awful.key {
			modifiers = { },
			key = 'Escape',
			on_press = function ()
				if submenu.visible then
					hide_submenu()
				else
					emoji_picker:hide()
				end
			end
		}
	},
	keypressed_callback = function (_, _, key)
		local text = search_bar_text.text

		if #key > 1 then
			if #text > 0 then
				if key == 'Return' then
					search_bar_text:set_text('NOT IMPLEMENTED')
				elseif key == 'BackSpace' then
					search_bar_text:set_text(text:sub(1, #text - 1))
				end
			end

			return
		elseif #text >= 32 then
			return
		end

		search_bar_text:set_text(text .. key)
	end,
	stop_callback = function ()
		search_bar_text:set_text('')
	end,
	mask_modkeys = true
}

-- tabbed groups
local groups = { }
local tabs = { }
local visible_group = nil
local is_first_group = true
local tab_tooltip = awful.tooltip { delay_show = 1 }

local function tab_mouseenter(self, _)
	tab_tooltip.text = self.tooltip
end

for _, group in ipairs(emoji_buttons) do
	local name = group.name
	local buttons = group.buttons

	-- add all group emojis to widget
	local group_widget = wibox.widget {
		layout = wibox.layout.grid,
		homogeneous = true,
		--forced_num_rows = picker_emoji_rows,
		forced_num_cols = picker_emoji_cols,
		visible = is_first_group
	}

	group_widget.approx_height = emoji_font_size * math.ceil(#buttons / picker_emoji_cols + 1)
	group_widget:add(table.unpack(buttons))
	table.insert(groups, group_widget)

	-- make tab
	local tab_widget = wibox.widget.textbox(buttons[1].text)

	tab_widget.font = emoji_font
	tab_widget.buttons = {
		awful.button {
			button = awful.button.names.LEFT,
			on_press = function ()
				-- hide current tab
				if visible_group then
					visible_group.visible = false
				end

				-- show this tab
				visible_group = group_widget
				visible_group.visible = true
			end
		}
	}

	tab_widget:connect_signal('mouse::enter', tab_mouseenter)

	tab_widget.tooltip = name
	tab_tooltip:add_to_object(tab_widget)

	table.insert(tabs, tab_widget)

	-- first group flag
	if is_first_group then
		is_first_group = false
		visible_group = group_widget
	end
end

-- container

emoji_picker = awful.popup {
	widget = {
		widget = wibox.container.background,
		bg = beautiful.bg_normal,
		shape = beautiful.shapes.rounded_rect,
		{
			widget = wibox.container.margin,
			margins = margins,
			{
				layout = wibox.layout.fixed.vertical,
				spacing = spacing,
				--search_bar
				search_bar,
				-- emojis
				{
					widget = wibox.container.constraint,
					strategy = 'exact',
					height = picker_height,
					{
						-- scrollable container
						widget = wibox.container.margin,
						margins = 0,
						buttons = {
							awful.button {
								modifiers = { },
								button = awful.button.names.SCROLL_DOWN,
								on_press = function (self)
									local top = self.widget.top
									local neg_height = -visible_group.approx_height

									if top == neg_height then return end

									top = top - emoji_font_size

									if top < neg_height then
										self.widget.top = neg_height
									else
										self.widget.top = top
									end
								end
							},
							awful.button {
								modifiers = { },
								button = awful.button.names.SCROLL_UP,
								on_press = function (self)
									local top = self.widget.top

									if top == 0 then return end

									top = top + emoji_font_size

									if top > 0 then
										self.widget.top = 0
									else
										self.widget.top = top
									end
								end
							}
						},
						-- emojis groups
						{
							layout = wibox.layout.stack,
							table.unpack(groups)
						}
					}
				},
				-- tabs
				{
					layout = wibox.layout.grid,
					homogeneous = true,
					forced_num_cols = picker_emoji_cols,
					table.unpack(tabs)
				}
			}
		}
	},
	placement = awful.placement.centered,
	shape = beautiful.shapes.rectangle,
	visible = false,
	ontop = true,
	bg = beautiful.transparent,
	fg = beautiful.fg_normal
}

function emoji_picker:show()
	emoji_picker.screen = mouse.screen
	emoji_picker.visible = true

	search_bar_keygrabber:start()
end

function emoji_picker:hide()
	emoji_picker.visible = false

	hide_submenu()
	search_bar_keygrabber:stop()
end

function emoji_picker:toggle()
	if emoji_picker.visible then
		emoji_picker:hide()
	else
		emoji_picker:show()
	end
end

-- signals

awesome.connect_signal(
	'utils::emoji-picker',
	function (is_visible)
		if type(is_visible) == 'boolean' then
			if is_visible then
				emoji_picker:show()
			else
				emoji_picker:hide()
			end
		else
			emoji_picker:toggle()
		end
	end)
