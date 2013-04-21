local ds = require "luci.dispatcher"

-- ------ interface configuration ------ --

m30 = Map("mwan3", translate("Multiwan interface configuration"),
	translate("The mwan3 multiwan package interfaces are configured here"))


mwan_interface = m30:section(TypedSection, "interface", translate("Multiwan interface aliases"),
	translate("Name must match the interface name found on the Network->Interfaces tab") .. "<br />" ..
	translate("Interfaces may not share the same name as configured members, policies or rules"))
	mwan_interface.addremove = true
	mwan_interface.dynamic = false
	mwan_interface.sortable = false
	mwan_interface.template = "cbi/tblsection"
	mwan_interface.extedit = ds.build_url("admin", "network", "multiwan", "interface", "%s")

	function mwan_interface.create(self, section)
		if TypedSection.create(self, section) then
			m30.uci:save("mwan3")
			luci.http.redirect(ds.build_url("admin", "network", "multiwan", "interface", section))
			return true
		else
			m30.message = translatef("There is already an entry named %q", section)
			return false
		end
	end


enabled = mwan_interface:option(DummyValue, "enabled", translate("Enabled"))
	function enabled.cfgvalue(self, s)
		return self.map:get(s, "enabled") or "-"
	end

track_ip = mwan_interface:option(DummyValue, "track_ip", translate("Test IP"))
	track_ip.rawhtml = true
	function track_ip.cfgvalue(self, s)
		local str = ""
		local tab = self.map:get(s, "track_ip")
		if tab then
			for k,v in pairs(tab) do
				str = str .. v .. "<br />"
			end
		else
			str = "none" .. "<br />"
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


return m30
