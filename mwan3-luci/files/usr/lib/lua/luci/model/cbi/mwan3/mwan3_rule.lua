local ds = require "luci.dispatcher"

-- ------ rule configuration ------ --

m5 = Map("mwan3", translate("MWAN3 Multi-WAN traffic rule configuration"),
	translate("<em>Sorting of rules affects MWAN3! Rules are read from top to bottom</em>"))


mwan_rule = m5:section(TypedSection, "rule", translate("Traffic rules"),
	translate("Name may contain characters A-Z, a-z, 0-9, _ and no spaces") .. "<br />" ..
	translate("Rules may not share the same name as configured interfaces, members or policies"))
	mwan_rule.addremove = true
	mwan_rule.anonymous = false
	mwan_rule.dynamic = false
	mwan_rule.sortable = true
	mwan_rule.template = "cbi/tblsection"
	mwan_rule.extedit = ds.build_url("admin", "network", "mwan3", "rule", "%s")

	function mwan_rule.create(self, section)
		if TypedSection.create(self, section) then
			m5.uci:save("mwan3")
			luci.http.redirect(ds.build_url("admin", "network", "mwan3", "rule", section))
			return true
		else
			m5.message = translatef("There is already an entry named %q", section)
			return false
		end
	end


src_ip = mwan_rule:option(DummyValue, "src_ip", translate("Source address"))
	function src_ip.cfgvalue(self, s)
		return self.map:get(s, "src_ip") or "-"
	end

src_port = mwan_rule:option(DummyValue, "src_port", translate("Source port"))
	function src_port.cfgvalue(self, s)
		return self.map:get(s, "src_port") or "-"
	end

dest_ip = mwan_rule:option(DummyValue, "dest_ip", translate("Destination address"))
	function dest_ip.cfgvalue(self, s)
		return self.map:get(s, "dest_ip") or "-"
	end

dest_port = mwan_rule:option(DummyValue, "dest_port", translate("Destination port"))
	function dest_port.cfgvalue(self, s)
		return self.map:get(s, "dest_port") or "-"
	end

proto = mwan_rule:option(DummyValue, "proto", translate("Protocol"))
	function proto.cfgvalue(self, s)
		return self.map:get(s, "proto") or "-"
	end

use_policy = mwan_rule:option(DummyValue, "use_policy", translate("Policy assigned"))
	function use_policy.cfgvalue(self, s)
		return self.map:get(s, "use_policy") or "-"
	end

equalize = mwan_rule:option(DummyValue, "equalize", translate("Equalize"))
	function equalize.cfgvalue(self, s)
		eqz = self.map:get(s, "equalize")
		if eqz == "1" then
			return "Yes"
		else
			return "No"
		end
	end


return m5
