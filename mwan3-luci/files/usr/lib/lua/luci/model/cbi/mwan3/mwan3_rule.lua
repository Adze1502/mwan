local ds = require "luci.dispatcher"

-- ------ rule configuration ------ --

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
		local sip = self.map:get(s, "src_ip")
		if sip then
			return "<br />" .. sip .. "<br /><br />"
		else
			return "<br /><font size=\"+4\">-</font><br />"
		end
	end

src_port = mwan_rule:option(DummyValue, "src_port", translate("Source port"))
	src_port.rawhtml = true
	function src_port.cfgvalue(self, s)
		local sprt = self.map:get(s, "src_port")
		if sprt then
			return sprt
		else
			return "<br /><font size=\"+4\">-</font>"
		end
	end

dest_ip = mwan_rule:option(DummyValue, "dest_ip", translate("Destination address"))
	dest_ip.rawhtml = true
	function dest_ip.cfgvalue(self, s)
		local dip = self.map:get(s, "dest_ip")
		if dip then
			return dip
		else
			return "<br /><font size=\"+4\">-</font>"
		end
	end

dest_port = mwan_rule:option(DummyValue, "dest_port", translate("Destination port"))
	dest_port.rawhtml = true
	function dest_port.cfgvalue(self, s)
		local dprt self.map:get(s, "dest_port")
		if dprt then
			return dprt
		else
			return "<br /><font size=\"+4\">-</font>"
		end
	end

proto = mwan_rule:option(DummyValue, "proto", translate("Protocol"))
	proto.rawhtml = true
	function proto.cfgvalue(self, s)
		local prtcl = self.map:get(s, "proto")
		if prtcl then
			return prtcl
		else
			return "<br /><font size=\"+4\">-</font>"
		end
	end

use_policy = mwan_rule:option(DummyValue, "use_policy", translate("Policy assigned"))
	use_policy.rawhtml = true
	function use_policy.cfgvalue(self, s)
		local upcy = self.map:get(s, "use_policy")
		if upcy then
			return upcy
		else
			return "<br /><font size=\"+4\">-</font>"
		end
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
