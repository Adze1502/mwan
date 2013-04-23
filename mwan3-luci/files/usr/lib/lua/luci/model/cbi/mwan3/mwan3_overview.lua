function mwan_get_status(rulenum)
	local status = luci.sys.exec("ip route list table " .. rulenum)
	local statuslen = string.len(status)
	if statuslen > 0 then
		return "ONLINE"
	else
		return "OFFLINE"
	end
end

function mwan_get_iface()
	local str = "\n"
	local rulenum = 1000
	uci.cursor():foreach("mwan3", "interface",
		function (section)
			rulenum = rulenum+1
			local enabled = luci.sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".enabled")
			local tracked = luci.sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".track_ip")
			local trackedlen = string.len(tracked)
			local status = mwan_get_status(rulenum)
			if enabled == "1\n" then
				if trackedlen > 0 then
					str = str .. section[".name"] .. ": " .. status .. "\n"
				else
					str = str .. section[".name"] .. ": " .. "not tracked" .. "\n"
				end
			else
				str = str .. section[".name"] .. ": " .. "not enabled" .. "\n"
			end
		end
	)
	return str
end

function mwan_str2tbl(s, p)
	local temp = {}
	local index = 0
	local last_index = string.len(s, p)

	while true do
		local i, e = string.find(s, p, index)

		if i and e then
			local next_index = e + 1
			local word_bound = i - 1
			table.insert(temp, string.sub(s, index, word_bound))
			index = next_index
		else            
			if index > 0 and index <= last_index then
				table.insert(temp, string.sub(s, index, last_index))
			elseif index == 0 then
				temp = nil
			end
		break
		end
	end

	return temp
end

-- ------ rule configuration ------ --

m5 = Map("luci", translate("Multiwan status"),
	translate("This page shows the current ONLINE/OFFLINE status of enabled and tracked mwan3 interfaces"))


overview = m5:section(NamedSection, "main", translate("UPDOWN"))
	overview.addremove = false
	overview.anonymous = true
	overview.dynamic = false


mwan_updown = overview:option(DummyValue, "mwan_updown", translate("Online status"))
	mwan_updown.rawhtml = true

	updownlst = mwan_get_iface()
	updowntbl = mwan_str2tbl(updownlst, "\n")
	function mwan_updown.cfgvalue(self, section)
		local str = ""
		for _, sup in pairs(updowntbl) do
			str = str .. sup .. "<br />"
		end
		return str .. "<br />"
	end


return m5
