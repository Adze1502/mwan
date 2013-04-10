local dsp = require "luci.dispatcher"

arg[1] = arg[1] or ""

-- ------ policy configuration ------ --

m10 = Map("mwan3", translate("Multiwan policy configuration"),
	translate("The mwan3 multiwan package policies are configured here"))

m10.redirect = dsp.build_url("admin", "network", "multiwan", "policy")

if not m10.uci:get(arg[1]) == "policy" then
	luci.http.redirect(m10.redirect)
	return
end

mwan_policy = m10:section(NamedSection, arg[1], "policy", "")
	mwan_policy.anonymous = false
	mwan_policy.addremove = false
	mwan_policy.dynamic = false


use_member = mwan_policy:option(DynamicList, "use_member", translate("Member used"),
	translate("Choose a member from the 'Available members' section below and enter its name here"))


-- ------ available members ------ --

mwan_member = m10:section(TypedSection, "member", translate("Available members"))
	mwan_member.addremove = false
	mwan_member.dynamic = false
	mwan_member.sortable = false
	mwan_member.template = "cbi/tblsection"


return m10
