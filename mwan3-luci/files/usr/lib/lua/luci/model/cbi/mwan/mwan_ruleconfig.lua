local dsp = require "luci.dispatcher"
local uci = require "luci.model.uci"

arg[1] = arg[1] or ""

function cbi_add_mwan(field)
        uci.cursor():foreach("mwan3", "policy",
                function (section)
                        field:value(section[".name"])
                end
        )
end

-- ------ rule configuration ------ --

m5 = Map("mwan3", translate("Multiwan rule configuration"),
	translate("The mwan3 multiwan package traffic rules are configured here"))

m5.redirect = dsp.build_url("admin", "network", "multiwan", "rule")

if not m5.uci:get(arg[1]) == "rule" then
	luci.http.redirect(m5.redirect)
	return
end

mwan_rule = m5:section(NamedSection, arg[1], "rule", "")
	mwan_rule.anonymous = false
	mwan_rule.addremove = false
	mwan_rule.dynamic = false


src_ip = mwan_rule:option(Value, "src_ip", translate("Source address"),
	translate("Supports CIDR notation (eg \"192.168.100.0/24\") without quotes"))
	src_ip.datatype = ipaddr

src_port = mwan_rule:option(Value, "src_port", translate("Source port"),
	translate("May be entered as a single port (eg \"1024\") or as a portrange (eg \"1024:2048\") without quotes"))

dest_ip = mwan_rule:option(Value, "dest_ip", translate("Destination address"),
	translate("Supports CIDR notation (eg \"192.168.100.0/24\") without quotes"))
	dest_ip.datatype = ipaddr

dest_port = mwan_rule:option(Value, "dest_port", translate("Destination port"),
	translate("May be entered as a single port (eg \"1024\") or as a portrange (eg \"1024:2048\") without quotes"))

proto = mwan_rule:option(ListValue, "proto", translate("Protocol"))
	proto.default = "all"
	proto:value("all")
	proto:value("tcp")
	proto:value("udp")
	proto:value("icmp")
	proto:value("esp")

use_policy = mwan_rule:option(Value, "use_policy", translate("Policy assigned"),
	translate("Choose a policy from the 'Available policies' section below and enter its name here"))
	cbi_add_mwan(use_policy)

equalize = mwan_rule:option(Flag, "equalize", translate("Equalize"),
	translate("") .. "<br />" ..
	translate("If checked mwan3 will load-balance each new session to the same host. If unchecked mwan3 will load-balance based on destination"))
	equalize.default = ""
	equalize.disabled = ""
	equalize.enabled = "1"


-- ------ currently configured policies ------ --

mwan_policy = m5:section(TypedSection, "policy", translate("Currently configured policies"))
	mwan_policy.addremove = false
	mwan_policy.dynamic = false
	mwan_policy.sortable = false
	mwan_policy.template = "cbi/tblsection"


return m5
