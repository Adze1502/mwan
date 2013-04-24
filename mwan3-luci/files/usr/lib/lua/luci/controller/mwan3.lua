module("luci.controller.mwan3", package.seeall)

function index()

	if not nixio.fs.access("/etc/config/mwan3") then
		return
	end

	entry({"admin", "network", "mwan3"},
		alias("admin", "network", "mwan3", "overview"),
		_("Multi-WAN (mwan3)"), 600)

	entry({"admin", "network", "mwan3", "status"},
		call("mwan3_status"))

	entry({"admin", "network", "mwan3", "overview"},
		cbi("mwan3/mwan3_overview"),
		_("Overview"), 10).leaf = true

	entry({"admin", "network", "mwan3", "interface"},
		arcombine(cbi("mwan3/mwan3_interface"), cbi("mwan3/mwan3_interfaceconfig")),
		_("Interfaces"), 20).leaf = true

	entry({"admin", "network", "mwan3", "member"},
		arcombine(cbi("mwan3/mwan3_member"), cbi("mwan3/mwan3_memberconfig")),
		_("Members"), 30).leaf = true

	entry({"admin", "network", "mwan3", "policy"},
		arcombine(cbi("mwan3/mwan3_policy"), cbi("mwan3/mwan3_policyconfig")),
		_("Policies"), 40).leaf = true

	entry({"admin", "network", "mwan3", "rule"},
		arcombine(cbi("mwan3/mwan3_rule"), cbi("mwan3/mwan3_ruleconfig")),
		_("Rules"), 50).leaf = true

	entry({"admin", "network", "mwan3", "troubleshoot"},
		cbi("mwan3/mwan3_troubleshoot"),
		_("Troubleshooting"), 60).leaf = true

end

function mwan_get_status(rulenum)
	local status = luci.sys.exec("ip route list table " .. rulenum)
		status = string.len(status)
	if status > 0 then
		return "on"
	else
		return "off"
	end
end

function mwan_get_iface()
	local str = ""
	local rulenum = 1000
	uci.cursor():foreach("mwan3", "interface",
		function (section)
			rulenum = rulenum+1
			local enabled = luci.sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".enabled")
			local tracked = luci.sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".track_ip")
				tracked = string.len(tracked)
			local status = mwan_get_status(rulenum)
			if enabled == "1\n" then
				if tracked > 0 then
					str = str .. section[".name"] .. "[" .. status .. "]"
				else
					str = str .. section[".name"] .. "[" .. "nm" .. "]"
				end
			else
				str = str .. section[".name"] .. "[" .. "ne" .. "]"
			end
		end
	)
	return str
end

function mwan3_status()
	local ntm = require "luci.model.network".init()

	local rv = {	}

	rv.wans = { }
	wansid = {}

	statstr = mwan_get_iface()
	for wanname, ifstat in string.gfind(statstr, "([^%[]+)%[([^%]]+)%]") do
		local wanifname = luci.sys.exec("uci get -p /var/state network." .. wanname .. ".ifname")
			local wanifnamelen = string.len(wanifname)
			if wanifnamelen == 0 then
				wanifname = "x"
			else
				wanifname = string.gsub(wanifname, "\n", "")
			end
		local wanlink = ntm:get_interface(wanifname)
			wanlink = wanlink and wanlink:get_network()
			wanlink = wanlink and wanlink:adminlink() or "#"
		wansid[wanname] = #rv.wans + 1
		rv.wans[wansid[wanname]] = { name = wanname, link = wanlink, ifname = wanifname, status = ifstat }
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end
