local awful = require('awful')
local beautiful = require('beautiful')
local wibox = require('wibox')

local widgets = require('widgets')

local margins = beautiful.margins
local spacing = beautiful.spacing

local moving_client = nil

-- tag list
local tag_list = awful.widget.taglist {
	screen = screen.primary,
	filter = awful.widget.taglist.filter.all,
	style = {
		shape = beautiful.shapes.rounded_rect
	},
	layout = {
		layout = wibox.layout.grid.vertical,
		spacing = spacing,
		forced_num_cols = 6,
		homogeneous = false
	},
	buttons = {
		awful.button(
			{ },
			awful.button.names.LEFT,
			nil,
			function (t)
				-- check if we are moving a client
				if moving_client then
					moving_client:tags{t}
					moving_client = nil

					return
				end

				-- view "desktop"
				t:view_only()
			end)
	},
	widget_template = {
		{
			{
				{
					{
						{
							{
								id = 'icon_role',
								widget = wibox.widget.imagebox
							},
							margins = margins,
							widget = wibox.container.margin
						},
						{
							{
								{
									text = ' X ',
									widget = wibox.widget.textbox
								},
								margins = margins,
								widget = wibox.container.margin
							},
							id = 'remove_role',
							widget = widgets.clickable
						},
						layout = wibox.layout.fixed.horizontal
					},
					{
						{
							{
								id = 'index_role',
								widget = wibox.widget.textbox
							},
							margins = margins,
							widget = wibox.container.margin
						},
						{
							{
								id = 'text_role',
								widget = wibox.widget.textbox
							},
							margins = margins,
							widget = wibox.container.margin
						},
						layout = wibox.layout.fixed.horizontal
					},
					layout = wibox.layout.fixed.vertical
				},
				margins = margins,
				widget = wibox.container.margin
			},
			id = 'background_role',
			widget = wibox.container.background
		},
		widget = widgets.clickable,
		create_callback = function(self, t, index)
			local remove_button = self:get_children_by_id('remove_role')[1]

			-- hide remove button on first tag
			if index == 1 then
				remove_button.visible = false
				return
			end

			remove_button:add_button(
				awful.button(
					{ },
					awful.button.names.LEFT,
					nil,
					function ()
						if tag.instances() <= 1 then return end

						-- TODO same tag name for all screens
						t:delete(t.screen.tags[1], true)
					end)
			)
		end
	}
}

-- virtual desktop popup

local new_desktop_button = wibox.widget {
	{
		{
			text = "+ New Desktop",
			widget = wibox.widget.textbox
		},
		margins = margins,
		widget = wibox.container.margin
	},
	widget = widgets.clickable
}

new_desktop_button:add_button(
	awful.button(
		{ },
		awful.button.names.LEFT,
		nil,
		function ()
			awesome.emit_signal('config::tags:add')
			awesome.emit_signal('desktop::virtual-desktop', false)
		end)
)

local popup = awful.popup {
	widget = {
		{
			{
				tag_list,
				new_desktop_button,
				layout = wibox.layout.fixed.vertical
			},
			margins = margins,
			widget = wibox.container.margin
		},
		bg = beautiful.primary,
		shape = beautiful.shapes.rounded_rect,
		widget = wibox.container.background
	},
	screen = screen.primary,
	ontop = true,
	maximum_width = screen.primary.geometry.width,
	maximum_height = screen.primary.geometry.height,
	bg = beautiful.transparent,
	shape = beautiful.shapes.rectangle,
	type = 'popup_menu',
	visible = false
}

local function show_popup(s)
	popup.screen = s or awful.screen.focused()

	awful.placement.top_left(
		popup,
		{
			honor_workarea = true,
			parent = s,
			margins = margins
		})

	awesome.emit_signal('desktop::mask:visible', true, popup.screen)
	popup.visible = true
end

local function hide_popup()
	awesome.emit_signal('desktop::mask:visible', false)
	popup.visible = false
end

-- signals

awesome.connect_signal(
	'desktop::virtual-desktop',
	function (is_visible)
		if type(is_visible) ~= 'boolean' then
			is_visible = not is_visible
		end

		if is_visible then
			show_popup()
		else
			hide_popup()
		end
	end)

awesome.connect_signal(
	'desktop::mask:dismissed',
	hide_popup)

awesome.connect_signal(
	'startup',
	function ()
		awesome.emit_signal(
			'desktop::task-list:add-context',
			'📲  Move to Desktop',
			function (c)
				moving_client = c
				show_popup()
			end)
	end)

--

return {
	create_button = require('desktop.virtual-desktops.create-button')
}
