local dsp = require "luci.dispatcher"
local uci = require "luci.model.uci"

arg[1] = arg[1] or ""

function cbi_add_mwan(field)
	uci.cursor():foreach("mwan3", "member",
		function (section)
			field:value(section[".name"])
		end
	)
end

-- ------ policy configuration ------ --

m10 = Map("mwan3", translate("MWAN3 Multi-WAN policy configuration - ") .. arg[1])

	m10.redirect = dsp.build_url("admin", "network", "mwan3", "policy")

	if not m10.uci:get(arg[1]) == "policy" then
		luci.http.redirect(m10.redirect)
		return
	end


mwan_policy = m10:section(NamedSection, arg[1], "policy", "")
	mwan_policy.addremove = false
	mwan_policy.dynamic = false


use_member = mwan_policy:option(DynamicList, "use_member", translate("Member used"))
	cbi_add_mwan(use_member)


-- ------ currently configured members ------ --

mwan_member = m10:section(TypedSection, "member", translate("Currently configured members"))
	mwan_member.addremove = false
	mwan_member.dynamic = false
	mwan_member.sortable = false
	mwan_member.template = "cbi/tblsection"


return m10
