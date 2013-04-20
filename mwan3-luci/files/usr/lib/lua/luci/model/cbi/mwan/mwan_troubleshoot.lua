-- ------ rule configuration ------ --

m5 = Map("luci", translate("Multiwan troubleshooting"),
	translate("This page will help troubleshoot mwan issues"))


troubleshoot = m5:section(NamedSection, "main", translate("Multiwan troubleshooting"))
	troubleshoot.addremove = false
	troubleshoot.anonymous = true
	troubleshoot.dynamic = false


mwan_iptables_refresh = troubleshoot:option(Button, "mwan_iptables_refresh", translate("Refresh troubleshooting tab"))
	function mwan_iptables_refresh.write(self, section, value)
		luci.util.exec("ls")
	end

mwan_iptables = troubleshoot:option(Value, "mwan_iptables", translate("Output of \"iptables -L -t mangle -v -n\""))
	mwan_iptables.template = "cbi/tvalue"
	mwan_iptables.rows = 15

	function mwan_iptables.cfgvalue(self, section)
		return luci.sys.exec("iptables -L -t mangle -v -n")
	end


return m5
