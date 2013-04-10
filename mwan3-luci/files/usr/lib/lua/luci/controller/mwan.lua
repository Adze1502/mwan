module("luci.controller.mwan", package.seeall)

function index()

        if not nixio.fs.access("/etc/config/mwan3") then
                return
        end

        entry({"admin", "network", "multiwan"},
                alias("admin", "network", "multiwan", "overview"),
                _("Multiwan"), 600)

	entry({"admin", "network", "multiwan", "overview"},
		cbi("mwan/mwan_overview", {autoapply=true}),
		_("Overview"), 10).leaf = true

        entry({"admin", "network", "multiwan", "interface"},
                arcombine(cbi("mwan/mwan_interface"), cbi("mwan/mwan_interfaceconfig")),
                _("Interfaces"), 20).leaf = true

        entry({"admin", "network", "multiwan", "member"},
                arcombine(cbi("mwan/mwan_member"), cbi("mwan/mwan_memberconfig")),
                _("Members"), 30).leaf = true

        entry({"admin", "network", "multiwan", "policy"},
                arcombine(cbi("mwan/mwan_policy"), cbi("mwan/mwan_policyconfig")),
                _("Policies"), 40).leaf = true

	entry({"admin", "network", "multiwan", "rule"},
		arcombine(cbi("mwan/mwan_rule"), cbi("mwan/mwan_ruleconfig")),
		_("Rules"), 50).leaf = true

end
