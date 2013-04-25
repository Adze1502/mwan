local ntm = require "luci.model.network".init()
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

-- ------ troubleshooting ------ --

m5 = Map("luci", translate("MWAN3 Multi-WAN troubleshooting"))


troubleshoot = m5:section(NamedSection, "main", translate("Multi-WAN troubleshooting"))
	troubleshoot.addremove = false
	troubleshoot.anonymous = true
	troubleshoot.dynamic = false


mwan_troubleshoot_refresh = troubleshoot:option(Button, "mwan_troubleshoot_refresh", translate("Refresh troubleshooting tab"))
	function mwan_troubleshoot_refresh.write(self, section, value)
		luci.util.exec("ls")
	end

mwan_version = troubleshoot:option(DummyValue, "mwan_version", translate("mwan3 version"))
	mwan_version.rawhtml = true

	version = luci.sys.exec("cat /usr/sbin/mwan3 | grep MWAN3_VERSION | awk -F: '{ print $2 }'")
	function mwan_version.cfgvalue(self, section)
		return version .. "<br />" .. "<br />"
	end

mwan_routeshow = troubleshoot:option(DummyValue, "mwan_routeshow", translate("Output of \"ip route show\""))
	mwan_routeshow.rawhtml = true

	routeshow = luci.sys.exec("ip route show")
	routeshowtbl = mwan_str2tbl(routeshow, "\n")
	function mwan_routeshow.cfgvalue(self, section)
		if routeshowtbl == nil then
			return "<br />" .. "<br />"
		else
			local str = ""
			for _, sup in pairs(routeshowtbl) do
				str = str .. sup .. "<br />"
			end
			return str .. "<br />"
		end
	end

mwan_iprules = troubleshoot:option(DummyValue, "mwan_iprules", translate("Output of \"ip rule show\""))
	mwan_iprules.rawhtml = true

	rulelisting = luci.sys.exec("ip rule show")
	rulelistingtbl = mwan_str2tbl(rulelisting, "\n")
	function mwan_iprules.cfgvalue(self, section)
		if rulelistingtbl == nil then
			return "<br />" .. "<br />"
		else
			local str = ""
			for _, rll in pairs(rulelistingtbl) do
				str = str .. rll .. "<br />"
			end
			return str .. "<br />"
		end
	end

mwan_iproutes = troubleshoot:option(DummyValue, "mwan_iproutes", translate("Output of \"ip route list table 1001-1027\""))
	mwan_iproutes.rawhtml = true

	routelisting = luci.sys.exec("ip rule | awk -F: '{ print $1 }' | awk '$1>=1001 && $1<=1027'")
	routelistingtbl = mwan_str2tbl(routelisting, "\n")
	function mwan_iproutes.cfgvalue(self, section)
		if routelistingtbl == nil then
			return "<br />" .. "<br />"
		else
			local str = ""
			for _, rtl in pairs(routelistingtbl) do
				bro = luci.sys.exec("ip route list table " .. rtl)
				str = str .. rtl .. "<br />" .. bro .. "<br />"
			end
			return str .. "<br />"
		end
	end
	

mwan_iptables = troubleshoot:option(DummyValue, "mwan_iptables", translate("Output of \"iptables -L -t mangle -v -n\""))
	mwan_iptables.template = "cbi/tvalue"
	mwan_iptables.rows = 15

	function mwan_iptables.cfgvalue(self, section)
		return luci.sys.exec("iptables -L -t mangle -v -n")
	end

mwan_ifconfig = troubleshoot:option(DummyValue, "mwan_ifconfig", translate("Output of \"ifconfig\""))
	mwan_ifconfig.template = "cbi/tvalue"
	mwan_ifconfig.rows = 15

	function mwan_ifconfig.cfgvalue(self, section)
		return luci.sys.exec("ifconfig")
	end

mwan_config = troubleshoot:option(DummyValue, "mwan_config", translate("Output of \"cat /etc/config/mwan3\""))
	mwan_config.template = "cbi/tvalue"
	mwan_config.rows = 15

	function mwan_config.cfgvalue(self, section)
		return luci.sys.exec("cat /etc/config/mwan3")
	end

mwan_netconfig = troubleshoot:option(DummyValue, "mwan_netconfig", translate("Output of \"cat /etc/config/network\""))
	mwan_netconfig.template = "cbi/tvalue"
	mwan_netconfig.rows = 15

	function mwan_netconfig.cfgvalue(self, section)
		return luci.sys.exec("cat /etc/config/network")
	end

mwan_logread = troubleshoot:option(DummyValue, "mwan_logread", translate("Output of \"logread | grep mwan3\""))
	mwan_logread.template = "cbi/tvalue"
	mwan_logread.rows = 15

	function mwan_logread.cfgvalue(self, section)
		return luci.sys.exec("logread | grep mwan3")
	end


return m5
