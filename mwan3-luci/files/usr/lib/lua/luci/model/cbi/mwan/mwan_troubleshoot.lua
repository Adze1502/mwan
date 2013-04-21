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

m5 = Map("luci", translate("Multiwan troubleshooting"),
	translate("This page will help troubleshoot mwan issues"))


troubleshoot = m5:section(NamedSection, "main", translate("Multiwan troubleshooting"))
	troubleshoot.addremove = false
	troubleshoot.anonymous = true
	troubleshoot.dynamic = false


mwan_troubleshoot_refresh = troubleshoot:option(Button, "mwan_troubleshoot_refresh", translate("Refresh troubleshooting tab"))
	function mwan_troubleshoot_refresh.write(self, section, value)
		luci.util.exec("ls")
	end

mwan_iprules = troubleshoot:option(DummyValue, "mwan_iprules", translate("Output of \"ip rule\""))
	mwan_iprules.rawhtml = true

	rulelisting = luci.sys.exec("ip rule")
	rulelistingtbl = mwan_str2tbl(rulelisting, "\n")
	function mwan_iprules.cfgvalue(self, section)
		local str = ""
		for _, rll in pairs(rulelistingtbl) do
			str = str .. rll .. "<br />"
		end
		return str
	end

mwan_iproutes = troubleshoot:option(DummyValue, "mwan_iproutes", translate("Output of \"ip route list table 1001-1015\""))
	mwan_iproutes.rawhtml = true

	routelisting = luci.sys.exec("ip rule | awk -F: '{ print $1 }' | awk '$1>=1001 && $1<=1015'")
	routelistingtbl = mwan_str2tbl(routelisting, "\n")
	function mwan_iproutes.cfgvalue(self, section)
		local str = ""
		for _, rtl in pairs(routelistingtbl) do
			bro = luci.sys.exec("ip route list table " .. rtl)
			str = str .. rtl .. "<br />" .. bro .. "<br />"
		end
		return str
	end
	

mwan_iptables = troubleshoot:option(DummyValue, "mwan_iptables", translate("Output of \"iptables -L -t mangle -v -n\""))
	mwan_iptables.template = "cbi/tvalue"
	mwan_iptables.rows = 15

	function mwan_iptables.cfgvalue(self, section)
		return luci.sys.exec("iptables -L -t mangle -v -n")
	end


return m5
