local beautiful = require('beautiful')
local wibox = require('wibox')

local dpi = beautiful.xresources.apply_dpi
local margins = beautiful.margins
local spacing = beautiful.spacing

--

---@param label string
---@param icon string
---@param callback fun(async_callback: fun(value: number))|fun(): number to update the meter value
---@param opts? {value:number,unit:string,format:string,min_value:number,max_value:number,delimiter:string}
local function create_meter(label, icon, callback, opts)
	if not opts then opts = { } end

	local unit = tostring(opts.unit or '')
	local format = tostring(opts.format or '%g')
	local min_value = tonumber(opts.min_value) or 0
	local max_value = tonumber(opts.max_value) or 100
	local delimiter = tostring(opts.delimiter or '|')

	local meter_value = wibox.widget {
		text = tostring(opts.value or ''),
		font = beautiful.font,
		align = 'left',
		widget = wibox.widget.textbox
	}

	local slider = wibox.widget {
		value = tonumber(opts.value) or 0,
		min_value = min_value,
		max_value = max_value,
		forced_height = dpi(12),
		color = beautiful.accent,
		background_color = beautiful.primary,
		shape = beautiful.shapes.rounded_rect,
		widget = wibox.widget.progressbar
	}

	local meter = wibox.widget {
		layout = wibox.layout.fixed.vertical,
		{
			layout = wibox.layout.fixed.horizontal,
			{
				text = string.format('%s %s ', label, delimiter),
				font = beautiful.font,
				align = 'left',
				widget = wibox.widget.textbox
			},
			meter_value,
			{
				text = unit,
				font = beautiful.font,
				align = 'left',
				widget = wibox.widget.textbox
			}
		},
		{
			layout = wibox.layout.fixed.horizontal,
			spacing = spacing,
			{
				{
					{
						image = icon,
						stylesheet = beautiful.icon_stylesheet,
						resize = true,
						widget = wibox.widget.imagebox
					},
					margins = margins,
					widget = wibox.container.margin
				},
				bg = beautiful.groups_bg,
				shape = beautiful.shapes.rounded_rect,
				widget = wibox.container.background
			},
			slider
		}
	}

	function meter:update()
		local value = tonumber(callback() or nil)

		if value then
			meter_value.text = string.format(format, value) or value
			slider.value = value
		end
	end

	function meter:update_async()
		callback(function (value)
			if value then
				meter_value.text = string.format(format, value) or value
				slider.value = value
			end
		end)
	end

	---@param name 'value'|'max_value'|'min_value'
	---@param value any
	function meter:set_option(name, value)
		if name == 'value' then
			meter_value.text = string.format(format, value) or value
			slider.value = value
		elseif name == 'max_value' then
			slider.max_value = value
		elseif name == 'min_value' then
			slider.min_value = value
		end
	end

	--
	return meter
end

--
return create_meter
