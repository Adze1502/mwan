local ds = require "luci.dispatcher"

-- ------ policy configuration ------ --

m10 = Map("mwan3", translate("MWAN3 Multi-WAN policy configuration"))


mwan_policy = m10:section(TypedSection, "policy", translate("Policies"),
	translate("Name may contain characters A-Z, a-z, 0-9, _ and no spaces") .. "<br />" ..
	translate("Policies may not share the same name as configured interfaces, members or rules"))
	mwan_policy.addremove = true
	mwan_policy.dynamic = false
	mwan_policy.sortable = false
	mwan_policy.template = "cbi/tblsection"
	mwan_policy.extedit = ds.build_url("admin", "network", "mwan3", "policy", "%s")

	function mwan_policy.create(self, section)
		if TypedSection.create(self, section) then
			m10.uci:save("mwan3")
			luci.http.redirect(ds.build_url("admin", "network", "mwan3", "policy", section))
			return true
		else
			m10.message = translatef("There is already an entry named %q", section)
			return false
		end
	end


use_member = mwan_policy:option(DummyValue, "use_member", translate("Members assigned"))
	use_member.rawhtml = true
	function use_member.cfgvalue(self, s)
		local str = ""
		local tab = self.map:get(s, "use_member")
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


return m10
