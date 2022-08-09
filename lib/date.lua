-- formatting https://www.cplusplus.com/reference/ctime/strftime/

local date = { }

---Formatted locale date string as
---"[Day of Week], [Month] [Day]"
---@param time? integer
---@return string
function date.tolocalestring(time)
	local day = os.date('%d', time)
	local first_digit = string.sub(day, 0, 1)
	local last_digit = string.sub(day, -1)
	local ordinal = nil

	if first_digit == '0' then
		day = last_digit
	end

	if last_digit == '1' and day ~= '11' then
		ordinal = 'st'
	elseif last_digit == '2' and day ~= '12' then
		ordinal = 'nd'
	elseif last_digit == '3' and day ~= '13' then
		ordinal = 'rd'
	else
		ordinal = 'th'
	end

	return os.date('%A, %B ', time) .. day .. ordinal
end

---Formatted ISO 8601 datetime string.
---@param time? integer
---@return string
function date.toisostring(time)
	return os.date('%FT%TZ', time)
end

return date
