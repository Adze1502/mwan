module("luci.controller.mwan3", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/mwan3") then
		return
	end

	entry({"admin", "network", "mwan3"},
		alias("admin", "network", "mwan3", "overview"),
		_("MWAN3 Multi-WAN"), 600)

	entry({"admin", "network", "mwan3", "status"},
		call("mwan3_status"))

	entry({"admin", "network", "mwan3", "tshoot"},
		call("mwan3_tshoot"))

	entry({"admin", "network", "mwan3", "overview"},
		template("mwan3_overview"),
		_("Overview"), 10)

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
		template("mwan3_troubleshoot"),
		_("Troubleshooting"), 60)

	entry({"admin", "network", "mwan3", "hotplug"},
		cbi("mwan3/mwan3_hotplug"), _("Hotplug Script"), 100)
end

function mwan3_get_status(rulenum, ifname)
	if luci.sys.exec("uci get -p /var/state mwan3." .. ifname .. ".enabled") == "1\n" then
		if string.len(luci.sys.exec("ip route list table " .. rulenum)) > 0 then
			if string.len(luci.sys.exec("uci get -p /var/state mwan3." .. ifname .. ".track_ip")) > 0 then
				return "on"
			else
				return "nm"
			end
		else
			return "off"
		end
	else
		return "ne"
	end
end

function mwan3_get_iface()
	local str = ""
	local rulenum = 1000
	uci.cursor():foreach("mwan3", "interface",
		function (section)
			rulenum = rulenum+1
			str = str .. section[".name"] .. "[" .. mwan3_get_status(rulenum, section[".name"]) .. "]"
		end
	)
	return str
end

function mwan3_status()
	local ntm = require "luci.model.network".init()

	local rv = {	}

	-- overview status
	local statstr = mwan3_get_iface()
	if string.len(statstr) > 0 then
		rv.wans = { }
		wansid = {}

		for wanname, ifstat in string.gfind(statstr, "([^%[]+)%[([^%]]+)%]") do
			local wanifname = luci.sys.exec("uci get -p /var/state network." .. wanname .. ".ifname | tr -d '\n'")
				if string.len(wanifname) == 0 then
					wanifname = "x"
				end
			local wanlink = ntm:get_interface(wanifname)
				wanlink = wanlink and wanlink:get_network()
				wanlink = wanlink and wanlink:adminlink() or "#"
			wansid[wanname] = #rv.wans + 1
			rv.wans[wansid[wanname]] = { name = wanname, link = wanlink, ifname = wanifname, status = ifstat }
		end
	end

	-- overview status log
	local mwlg = string.gsub(luci.sys.exec("logread | grep mwan3 | tail -n 50 | sed 'x;1!H;$!d;x'"), "\n", "<br />")
	if string.len(mwlg) > 0 then
		mwlg = "<br />" .. mwlg .. "<br />"
		rv.mwan3log = { }
		mwlog = {}
		mwlog[mwlg] = #rv.mwan3log + 1
		rv.mwan3log[mwlog[mwlg]] = { mwanlog = mwlg }
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function mwan3_tshoot()
	local rv = {	}

	-- mwan3 and mwan3-luci version
	local mwan3version = string.gsub(luci.sys.exec("opkg info mwan3 | grep Version | awk -F' ' '{ print $2 }'"), "\n", "<br />")
		if string.len(mwan3version) > 0 then
			mwan3version = "<br />mwan3 - " .. mwan3version
		else
			mwan3version = "<br />mwan3 - unknown<br />"
		end
	local mwan3lversion = string.gsub(luci.sys.exec("opkg info luci-app-mwan3 | grep Version | awk -F' ' '{ print $2 }'"), "\n", "<br /><br />")
		if string.len(mwan3lversion) > 0 then
			mwan3lversion = "luci-app-mwan3 - " .. mwan3lversion
		else
			mwan3lversion = "luci-app-mwan3 - unknown<br /><br />"
		end
	local mwan3apps = mwan3version .. mwan3lversion
	rv.mw3ver = { }
	mwv = {}
	mwv[mwan3apps] = #rv.mw3ver + 1
	rv.mw3ver[mwv[mwan3apps]] = { mwan3v = mwan3apps }

	-- default firewall output policy
	local defout = string.gsub(luci.sys.exec("uci get -p /var/state firewall.@defaults[0].output"), "\n", "<br /><br />")
		if string.len(defout) ~= 0 then
			defout = "<br />" .. defout
		else
			defout = "<br />No data found<br /><br />"
		end
	rv.fidef = { }
	fwdf = {}
	fwdf[defout] = #rv.fidef + 1
	rv.fidef[fwdf[defout]] = { firedef = defout }

	-- ip route show
	local routeshow = "<br />" .. string.gsub(luci.sys.exec("ip route show"), "\n", "<br />") .. "<br />"
	rv.rtshow = { }
	rshw = {}
	rshw[routeshow] = #rv.rtshow + 1
	rv.rtshow[rshw[routeshow]] = { iprtshow = routeshow }

	-- ip rule show
	local ipr = "<br />" .. string.gsub(luci.sys.exec("ip rule show"), "\n", "<br />") .. "<br />"
	rv.iprule = { }
	ipruleid = {}
	ipruleid[ipr] = #rv.iprule + 1
	rv.iprule[ipruleid[ipr]] = { rule = ipr }

	-- ip route list table
	local routelisting = luci.sys.exec("ip rule | awk -F: '{ print $1 }' | awk '$1>=1001 && $1<=1099'")
	local rlstr = ""
		if string.len(routelisting) > 0 then
			for line in routelisting:gmatch("[^\r\n]+") do
				rlstr = rlstr .. line .. "<br />" .. luci.sys.exec("ip route list table " .. line)
			end
			rlstr = "<br />" .. rlstr .. "<br />"
		else
			rlstr = "<br />No data found<br /><br />"
		end
	rv.routelist = { }
	rtlist = {}
	rtlist[rlstr] = #rv.routelist + 1
	rv.routelist[rtlist[rlstr]] = { iprtlist = rlstr }

	-- iptables
	local iptbl = string.gsub(luci.sys.exec("iptables -L -t mangle -v -n | awk '/mwan3/' RS= | sed -e 's/.*Chain.*/\\n&/'"), "\n", "<br />")
		if string.len(iptbl) ~= 0 then
			iptbl = iptbl .. "<br />"
		else
			iptbl = "<br />No data found<br /><br />"
		end
	rv.iptables = { }
	tables = {}
	tables[iptbl] = #rv.iptables + 1
	rv.iptables[tables[iptbl]] = { iptbls = iptbl }

	-- ifconfig
	local ifcg = "<br />" .. string.gsub(luci.sys.exec("ifconfig"), "\n", "<br />")
	rv.ifconfig = { }
	icfg = {}
	icfg[ifcg] = #rv.ifconfig + 1
	rv.ifconfig[icfg[ifcg]] = { ifcfg = ifcg }

	-- mwan3 config
	local mwcg = string.gsub(luci.sys.exec("cat /etc/config/mwan3"), "\n", "<br />")
		if string.len(mwcg) == 0 then
			mwcg = "<br />No data found<br /><br />"
		end
	rv.mwan3config = { }
	mwan3cfg = {}
	mwan3cfg[mwcg] = #rv.mwan3config + 1
	rv.mwan3config[mwan3cfg[mwcg]] = { mwn3cfg = mwcg }

	-- network config
	local netcg = string.gsub(luci.sys.exec("cat /etc/config/network | sed -e 's/.*username.*/	USERNAME HIDDEN/' -e 's/.*password.*/	PASSWORD HIDDEN/'"), "\n", "<br />")
	rv.netconfig = { }
	ncfg = {}
	ncfg[netcg] = #rv.netconfig + 1
	rv.netconfig[ncfg[netcg]] = { netcfg = netcg }

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end
