local ds = require "luci.dispatcher"

function ifacenum()
	local ifnum = 0
	uci.cursor():foreach("mwan3", "interface",
		function (section)
			ifnum = ifnum+1
		end
	)
	if ifnum == 0 then
		return "<em>There are no interfaces configured!</em>"
	elseif ifnum == 1 then
		return "<em>There is currently 1 of 15 supported interfaces configured!</em>"
	elseif ifnum <= 15 then
		return "<em>There are currently " .. ifnum .. " of 15 supported interfaces configured!</em>"
	else
		return "<em>WARNING: " .. ifnum .. " interfaces are configured exceeding the maximum of 15!</em>"
	end
end

-- ------ interface configuration ------ --

m5 = Map("mwan3", translate("MWAN3 Multi-WAN Interface Configuration"),
	translate(ifacenum()))


mwan_interface = m5:section(TypedSection, "interface", translate("Interfaces"),
	translate("MWAN3 supports up to 15 physical and/or logical interfaces<br />") ..
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


return m5
