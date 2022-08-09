local h = { }
local history = { }
local is_enabled = true

function h.add_client(c)
	if not is_enabled then return end
	if c.skip_taskbar then return end

	local cid = c.window

	-- insert new client into top of history
	table.insert(history, 1, cid)
end

function h.remove_client(c)
	if not is_enabled then return end

	local cid = c.window

	-- find client by id and remove from history
	for i, hid in ipairs(history) do
		if cid == hid then
			table.remove(history, i)
			break
		end
	end
end

function h.focus_client(c)
	if not is_enabled then return end

	local cid = c.window

	for i, hid in ipairs(history) do
		if cid == hid then
			table.insert(history, 1, table.remove(history, i))
			break
		end
	end
end

---Gets the ordered client list
---@return table
function h.get_client_list()
	local list = { }
	local clients = client.get()

	for _, cid in ipairs(history) do
		for i, c in ipairs(clients) do
			if c.window == cid then
				table.insert(list, c)
				table.remove(clients, i)
				break
			end
		end
	end

	return list
end

local index = 1

function h.enable_tracking()
	local c = client.focus

	is_enabled = true
	index = 1

	if c then h.focus_client(c) end
end

function h.disable_tracking()
	is_enabled = false
end

---Focus a client by index in historical order.
---@param i number Positive number wrap to the beginning, negative numbers work backwards.
function h.focus_index(i)
	if type(i) ~= 'number' then return end
	if #history == 0 then return end

	local cid = 0

	if i > 0 then
		cid = history[(i - 1) % #history + 1]
	else
		cid = history[(i + #history) % #history + 1]
	end

	for _, c in ipairs(client.get()) do
		if c.window == cid then
			c:activate { raise = true }
			break
		end
	end
end

function h.focus_previous()
	if index == -1 then index = 0 end
	h.focus_index(index + 1)

	if not is_enabled then index = index + 1 end
end

function h.focus_next()
	if index == 1 then index = 0 end
	h.focus_index(index - 1)

	if not is_enabled then index = index - 1 end
end

-- signals

client.connect_signal('request::manage', function (c) h.add_client(c) end)
client.connect_signal('request::unmanage', function (c) h.remove_client(c) end)
client.connect_signal('focus', function (c) h.focus_client(c) end)

--
return h
