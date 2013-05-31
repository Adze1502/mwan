-- ------ rule configuration ------ --

local ds = require "luci.dispatcher"


m5 = Map("mwan3", translate("MWAN3 Multi-WAN traffic Rule Configuration"),
	translate("<strong><em>Sorting of rules affects MWAN3! Rules are read from top to bottom</em></strong>"))


mwan_rule = m5:section(TypedSection, "rule", translate("Traffic Rules"),
	translate("Name may contain characters A-Z, a-z, 0-9, _ and no spaces<br />") ..
	translate("Rules may not share the same name as configured interfaces, members or policies"))
	mwan_rule.addremove = true
	mwan_rule.anonymous = false
	mwan_rule.dynamic = false
	mwan_rule.sortable = true
	mwan_rule.template = "cbi/tblsection"
	mwan_rule.extedit = ds.build_url("admin", "network", "mwan3", "rule", "%s")
	function mwan_rule.create(self, section)
		TypedSection.create(self, section)
		m5.uci:save("mwan3")
		luci.http.redirect(ds.build_url("admin", "network", "mwan3", "rule", section))
	end


src_ip = mwan_rule:option(DummyValue, "src_ip", translate("Source address"))
	src_ip.rawhtml = true
	function src_ip.cfgvalue(self, s)
		return self.map:get(s, "src_ip") or "<br /><font size=\"+4\">-</font><br />"
	end

src_port = mwan_rule:option(DummyValue, "src_port", translate("Source port"))
	src_port.rawhtml = true
	function src_port.cfgvalue(self, s)
		return self.map:get(s, "src_port") or "<br /><font size=\"+4\">-</font>"
	end

dest_ip = mwan_rule:option(DummyValue, "dest_ip", translate("Destination address"))
	dest_ip.rawhtml = true
	function dest_ip.cfgvalue(self, s)
		return self.map:get(s, "dest_ip") or "<br /><font size=\"+4\">-</font>"
	end

dest_port = mwan_rule:option(DummyValue, "dest_port", translate("Destination port"))
	dest_port.rawhtml = true
	function dest_port.cfgvalue(self, s)
		return self.map:get(s, "dest_port") or "<br /><font size=\"+4\">-</font>"
	end

proto = mwan_rule:option(DummyValue, "proto", translate("Protocol"))
	proto.rawhtml = true
	function proto.cfgvalue(self, s)
		return self.map:get(s, "proto") or "<br /><font size=\"+4\">-</font>"
	end

use_policy = mwan_rule:option(DummyValue, "use_policy", translate("Policy assigned"))
	use_policy.rawhtml = true
	function use_policy.cfgvalue(self, s)
		return self.map:get(s, "use_policy") or "<br /><font size=\"+4\">-</font>"
	end

equalize = mwan_rule:option(DummyValue, "equalize", translate("Equalize"))
	function equalize.cfgvalue(self, s)
		if self.map:get(s, "equalize") == "1" then
			return "Yes"
		else
			return "No"
		end
	end


return m5
