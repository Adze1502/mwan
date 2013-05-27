local ds = require "luci.dispatcher"

function ifacewarn()
	local warns = ""
	local ifnum = 0
	local metfail = 0
	uci.cursor():foreach("mwan3", "interface",
		function (section)
			ifnum = ifnum+1

			local metcheck = luci.sys.exec("uci get -p /var/state network." .. section[".name"] .. ".metric")
			if string.len(metcheck) == 0 then
				metfail = metfail+1
			end
		end
	)
	if ifnum <= 15 then
		warns = "<strong><em>There are currently " .. ifnum .. " of 15 supported interfaces configured!</em></strong>"
	else
		warns = "<font color=\"ff0000\"><strong><em>WARNING: " .. ifnum .. " interfaces are configured exceeding the maximum of 15!</em></strong></font>"
	end
	if metfail > 0 then
		warns = warns .. "<br /><br /><font color=\"ff0000\"><strong><em>WARNING: some interfaces have no metric</em></strong></font>"
	end
	return warns
end

-- ------ interface configuration ------ --

m5 = Map("mwan3", translate("MWAN3 Multi-WAN Interface Configuration"),
	translate(ifacewarn()))


mwan_interface = m5:section(TypedSection, "interface", translate("Interfaces"),
	translate("MWAN3 supports up to 15 physical and/or logical interfaces<br />") ..
	translate("MWAN3 requires that all interfaces have a unique metric configured in /etc/config/network<br />") ..
	translate("Name must match the interface name found in /etc/config/network (see troubleshooting tab)<br />") ..
	translate("Name may contain characters A-Z, a-z, 0-9, _ and no spaces<br />") ..
	translate("Interfaces may not share the same name as configured members, policies or rules"))
	mwan_interface.addremove = true
	mwan_interface.dynamic = false
	mwan_interface.sortable = false
	mwan_interface.template = "cbi/tblsection"
	mwan_interface.extedit = ds.build_url("admin", "network", "mwan3", "interface", "%s")

	function mwan_interface.create(self, section)
		TypedSection.create(self, section)
		m5.uci:save("mwan3")
		luci.http.redirect(ds.build_url("admin", "network", "mwan3", "interface", section))
	end


enabled = mwan_interface:option(DummyValue, "enabled", translate("Enabled"))
	function enabled.cfgvalue(self, s)
		enbld = self.map:get(s, "enabled")
		if enbld == "1" then
			return "Yes"
		else
			return "No"
		end
	end

track_ip = mwan_interface:option(DummyValue, "track_ip", translate("Test IP"))
	track_ip.rawhtml = true
	function track_ip.cfgvalue(self, s)
		local str = "<br />"
		local tab = self.map:get(s, "track_ip")
		if tab then
			for k,v in pairs(tab) do
				str = str .. v .. "<br />"
			end
		else
			str = "<br />-<br />"
		end
		str = str .. "<br />"
		return str
	end

reliability = mwan_interface:option(DummyValue, "reliability", translate("Test IP reliability"))
	function reliability.cfgvalue(self, s)
		return self.map:get(s, "reliability") or "-"
	end

count = mwan_interface:option(DummyValue, "count", translate("Ping count"))
	function count.cfgvalue(self, s)
		return self.map:get(s, "count") or "-"
	end

timeout = mwan_interface:option(DummyValue, "timeout", translate("Ping timeout"))
	function timeout.cfgvalue(self, s)
		return self.map:get(s, "timeout") or "-"
	end

interval = mwan_interface:option(DummyValue, "interval", translate("Ping interval"))
	function interval.cfgvalue(self, s)
		return self.map:get(s, "interval") or "-"
	end

down = mwan_interface:option(DummyValue, "down", translate("Interface down"))
	function down.cfgvalue(self, s)
		return self.map:get(s, "down") or "-"
	end

up = mwan_interface:option(DummyValue, "up", translate("Interface up"))
	function up.cfgvalue(self, s)
		return self.map:get(s, "up") or "-"
	end

metric = mwan_interface:option(DummyValue, "metric", translate("Metric"))
	function metric.cfgvalue(self, s)
		str = luci.sys.exec("uci get -p /var/state network." .. s .. ".metric")
		if string.len(str) == 0 then
			return "-"
		end
		return str
	end


return m5
