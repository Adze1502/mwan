local ds = require "luci.dispatcher"

arg[1] = arg[2] or ""


-- ------ rule configuration ------ --

m5 = Map("mwan3", translate("Multiwan"),
	translate("The mwan3 package handles failover and load balancing between up to 7 WAN interfaces"))

overview = m5:section(TypedSection, "mwan_overview", translate("Multiwan overview"))
	overview.addremove = false
	overview.anonymous = true
	overview.dynamic = false

overview:tab("mwan_troubleshooting_tab", translate("Multiwan troubleshooting"))

mwan_iptables_refresh = overview:taboption("mwan_troubleshooting_tab", Button, "mwan_iptables_refresh", translate("Refresh troubleshooting tab"))
	function mwan_iptables_refresh.write(self, section, value)
		luci.util.exec("ls")
	end

mwan_iptables = overview:taboption("mwan_troubleshooting_tab", Value, "mwan_iptables", translate("Output of \"iptables -L -t mangle -v -n\""))

	mwan_iptables.template = "cbi/tvalue"
	mwan_iptables.rows = 10

	function mwan_iptables.cfgvalue(self, section)
		return luci.sys.exec("iptables -L -t mangle -v -n")
	end


return m5
