local ds = require "luci.dispatcher"

-- ------ member configuration ------ --

m20 = Map("mwan3", translate("Multiwan member configuration"),
	translate("The mwan3 multiwan package members are configured here"))


mwan_member = m20:section(TypedSection, "member", translate("Members"),
	translate("Name may contain characters A-Z, a-z, 0-9, _ and no spaces") .. "<br />" ..
	translate("Members may not share the same name as configured interfaces, policies or rules"))
	mwan_member.addremove = true
	mwan_member.dynamic = false
	mwan_member.sortable = false
	mwan_member.template = "cbi/tblsection"
	mwan_member.extedit = ds.build_url("admin", "network", "multiwan", "member", "%s")

	function mwan_member.create(self, section)
		if TypedSection.create(self, section) then
			m20.uci:save("mwan3")
			luci.http.redirect(ds.build_url("admin", "network", "multiwan", "member", section))
			return true
		else
			m20.message = translatef("There is already an entry named %q", section)
			return false
		end
	end


interface = mwan_member:option(DummyValue, "interface", translate("Interface"))
	function interface.cfgvalue(self, s)
		return self.map:get(s, "interface") or "-"
	end

metric = mwan_member:option(DummyValue, "metric", translate("Metric"))
	function metric.cfgvalue(self, s)
		return self.map:get(s, "metric") or "-"
	end

weight = mwan_member:option(DummyValue, "weight", translate("Weight"))
	function weight.cfgvalue(self, s)
		return self.map:get(s, "weight") or "-"
	end


return m20
