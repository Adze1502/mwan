-- ------ extra functions ------ --

function cbi_add_member(field)
	uci.cursor():foreach("mwan3", "member",
		function (section)
			field:value(section[".name"])
		end
	)
end

-- ------ policy configuration ------ --

dsp = require "luci.dispatcher"
arg[1] = arg[1] or ""


m5 = Map("mwan3", translate("MWAN3 Multi-WAN Policy Configuration - ") .. arg[1])
	m5.redirect = dsp.build_url("admin", "network", "mwan3", "policy")


mwan_policy = m5:section(NamedSection, arg[1], "policy", "")
	mwan_policy.addremove = false
	mwan_policy.dynamic = false


use_member = mwan_policy:option(DynamicList, "use_member", translate("Member used"))
	cbi_add_member(use_member)


-- ------ currently configured members ------ --

mwan_member = m5:section(TypedSection, "member", translate("Currently Configured Members"))
	mwan_member.addremove = false
	mwan_member.dynamic = false
	mwan_member.sortable = false
	mwan_member.template = "cbi/tblsection"


return m5
