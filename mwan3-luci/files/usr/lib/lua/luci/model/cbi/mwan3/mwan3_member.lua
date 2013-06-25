-- ------ member configuration ------ --

ds = require "luci.dispatcher"


m5 = Map("mwan3", translate("MWAN3 Multi-WAN Member Configuration"))


mwan_member = m5:section(TypedSection, "member", translate("Members"),
	translate("MWAN3 supports an unlimited number of members<br />" ..
	"Name may contain characters A-Z, a-z, 0-9, _ and no spaces<br />" ..
	"Members may not share the same name as configured interfaces, policies or rules"))
	mwan_member.addremove = true
	mwan_member.dynamic = false
	mwan_member.sortable = false
	mwan_member.template = "cbi/tblsection"
	mwan_member.extedit = ds.build_url("admin", "network", "mwan3", "member", "%s")
	function mwan_member.create(self, section)
		TypedSection.create(self, section)
		m5.uci:save("mwan3")
		luci.http.redirect(ds.build_url("admin", "network", "mwan3", "member", section))
	end


interface = mwan_member:option(DummyValue, "interface", translate("Interface"))
	interface.rawhtml = true
	function interface.cfgvalue(self, s)
		local interfc = self.map:get(s, "interface")
		if interfc then
			return "<br />" .. interfc .. "<br /><br />"
		else
			return "<br /><font size=\"+4\">-</font>"
		end
	end

metric = mwan_member:option(DummyValue, "metric", translate("Metric"))
	metric.rawhtml = true
	function metric.cfgvalue(self, s)
		return self.map:get(s, "metric") or "<br /><font size=\"+4\">-</font>"
	end

weight = mwan_member:option(DummyValue, "weight", translate("Weight"))
	weight.rawhtml = true
	function weight.cfgvalue(self, s)
		return self.map:get(s, "weight") or "<br /><font size=\"+4\">-</font>"
	end


return m5
