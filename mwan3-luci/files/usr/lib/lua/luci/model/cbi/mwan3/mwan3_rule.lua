-- ------ extra functions ------ --

function rule_check() -- determine if rules needs a proper protocol configured
	uci.cursor():foreach("mwan3", "rule",
		function (section)
			local sport = ut.trim(sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".src_port"))
			local dport = ut.trim(sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".dest_port"))
			if sport ~= "" or dport ~= "" then -- ports configured
				local proto = ut.trim(sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".proto"))
				if proto == "" or proto == "all" then -- no or improper protocol
					err_proto_list = err_proto_list .. section[".name"] .. " "
				end
			end
		end
	)
end

function rule_warn() -- display warning messages at the top of the page
	if err_proto_list ~= " " then
		return "<font color=\"ff0000\"><strong>WARNING: some rules have a port configured with no or improper protocol specified! Please configure a specific protocol!</strong></font>"
	else
		return ""
	end
end

-- ------ rule configuration ------ --

dsp = require "luci.dispatcher"
sys = require "luci.sys"
ut = require "luci.util"

err_proto = 0
err_proto_list = " "
rule_check()


m5 = Map("mwan3", translate("MWAN3 Multi-WAN Traffic Rule Configuration"),
	translate(rule_warn()))
	m5:append(Template("mwan3/mwan3_config_css"))


mwan_rule = m5:section(TypedSection, "rule", translate("Traffic Rules"),
	translate("Rules specify which traffic will use a particular MWAN3 policy based on IP address, port or protocol<br />" ..
	"Rules are matched from top to bottom. Rules below a matching rule are ignored. Traffic not matching any rule is routed using the main routing table<br />" ..
	"Traffic destined for known (other than default) networks is handled by the main routing table. Traffic matching a rule, but all WAN interfaces for that policy are down will be blackholed<br />" ..
	"Names may contain characters A-Z, a-z, 0-9, _ and no spaces<br />" ..
	"Rules may not share the same name as configured interfaces, members or policies"))
	mwan_rule.addremove = true
	mwan_rule.anonymous = false
	mwan_rule.dynamic = false
	mwan_rule.sectionhead = "Rule"
	mwan_rule.sortable = true
	mwan_rule.template = "cbi/tblsection"
	mwan_rule.extedit = dsp.build_url("admin", "network", "mwan3", "configuration", "rule", "%s")
	function mwan_rule.create(self, section)
		TypedSection.create(self, section)
		m5.uci:save("mwan3")
		luci.http.redirect(dsp.build_url("admin", "network", "mwan3", "configuration", "rule", section))
	end


src_ip = mwan_rule:option(DummyValue, "src_ip", translate("Source address"))
	src_ip.rawhtml = true
	function src_ip.cfgvalue(self, s)
		return self.map:get(s, "src_ip") or "&#8212;"
	end

src_port = mwan_rule:option(DummyValue, "src_port", translate("Source port"))
	src_port.rawhtml = true
	function src_port.cfgvalue(self, s)
		return self.map:get(s, "src_port") or "&#8212;"
	end

dest_ip = mwan_rule:option(DummyValue, "dest_ip", translate("Destination address"))
	dest_ip.rawhtml = true
	function dest_ip.cfgvalue(self, s)
		return self.map:get(s, "dest_ip") or "&#8212;"
	end

dest_port = mwan_rule:option(DummyValue, "dest_port", translate("Destination port"))
	dest_port.rawhtml = true
	function dest_port.cfgvalue(self, s)
		return self.map:get(s, "dest_port") or "&#8212;"
	end

proto = mwan_rule:option(DummyValue, "proto", translate("Protocol"))
	proto.rawhtml = true
	function proto.cfgvalue(self, s)
		return self.map:get(s, "proto") or "all"
	end

use_policy = mwan_rule:option(DummyValue, "use_policy", translate("Policy assigned"))
	use_policy.rawhtml = true
	function use_policy.cfgvalue(self, s)
		return self.map:get(s, "use_policy") or "&#8212;"
	end

errors = mwan_rule:option(DummyValue, "errors", translate("Errors"))
	errors.rawhtml = true
	function errors.cfgvalue(self, s)
		if not string.find(err_proto_list, " " .. s .. " ") then
			return ""
		else
			return "<span title=\"No protocol specified\"><img src=\"/luci-static/resources/cbi/reset.gif\" alt=\"error\"></img></span>"
		end
	end


return m5
