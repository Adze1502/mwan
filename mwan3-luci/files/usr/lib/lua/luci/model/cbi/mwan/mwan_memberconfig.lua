local dsp = require "luci.dispatcher"

arg[1] = arg[1] or ""

-- ------ member configuration ------ --

m20 = Map("mwan3", translate("Multiwan member configuration"),
	translate("The mwan3 multiwan package members are configured here"))

m20.redirect = dsp.build_url("admin", "network", "multiwan", "member")

if not m20.uci:get(arg[1]) == "member" then
	luci.http.redirect(m20.redirect)
	return
end

mwan_member = m20:section(NamedSection, arg[1], "member", "")
	mwan_member.anonymous = false
	mwan_member.addremove = false
	mwan_member.dynamic = false

interface = mwan_member:option(Value, "interface", translate("Interface"),
	translate("Choose an interface from the 'Available interfaces' section below and enter its name here"))

metric = mwan_member:option(Value, "metric", translate("Metric"),
	translate("Acceptable values: 1-1000"))
	metric.datatype = "range(1, 1000)"

weight = mwan_member:option(Value, "weight", translate("Weight"),
	translate("Acceptable values: 1-1000"))
	weight.datatype = "range(1, 1000)"


-- ------ available interfaces ------ --

mwan_interface = m20:section(TypedSection, "interface", translate("Available interfaces"))
	mwan_interface.addremove = false
	mwan_interface.dynamic = false
	mwan_interface.sortable = false
	mwan_interface.template = "cbi/tblsection"


return m20
