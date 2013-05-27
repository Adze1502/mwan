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
			if enabled == "1\n" then
				local tracked = luci.sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".track_ip")
					tracked = string.len(tracked)
				if tracked > 0 then
					local status = mwan_get_status(rulenum)
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

	-- overview status
	statstr = mwan_get_iface()
	if string.len(statstr) > 0 then
		rv.wans = { }
		wansid = {}

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
	end

	-- overview status log
	local mwlg = luci.sys.exec("logread | grep mwan3 | tail -n 50 | sed 'x;1!H;$!d;x'")
	if string.len(mwlg) > 0 then
		mwlg =  "<br />" .. string.gsub(mwlg, "\n", "<br />") .. "<br />"
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
	local mwan3version = luci.sys.exec("opkg info mwan3 | grep Version | awk -F' ' '{ print $2 }'")
		if string.len(mwan3version) > 0 then
			mwan3version = "<br />mwan3 - " .. string.gsub(mwan3version, "\n", "<br />")
		else
			mwan3version = "<br />mwan3 - unknown<br />"
		end
	local mwan3lversion = luci.sys.exec("opkg info luci-app-mwan3 | grep Version | awk -F' ' '{ print $2 }'")
		if string.len(mwan3lversion) > 0 then
			mwan3lversion = "luci-app-mwan3 - " .. string.gsub(mwan3lversion, "\n", "<br /><br />")
		else
			mwan3lversion = "luci-app-mwan3 - unknown<br /><br />"
		end
	local mwan3apps = mwan3version .. mwan3lversion
	rv.mw3ver = { }
	mwv = {}
	mwv[mwan3apps] = #rv.mw3ver + 1
	rv.mw3ver[mwv[mwan3apps]] = { mwan3v = mwan3apps }

	-- default firewall output policy
	local defout = luci.sys.exec("uci get -p /var/state firewall.@defaults[0].output")
		defout = "<br />" .. string.gsub(defout, "\n", "<br /><br />")
	rv.fidef = { }
	fwdf = {}
	fwdf[defout] = #rv.fidef + 1
	rv.fidef[fwdf[defout]] = { firedef = defout }

	-- ip route show
	local routeshow = luci.sys.exec("ip route show")
		routeshow = "<br />" .. string.gsub(routeshow, "\n", "<br />") .. "<br />"
	rv.rtshow = { }
	rshw = {}
	rshw[routeshow] = #rv.rtshow + 1
	rv.rtshow[rshw[routeshow]] = { iprtshow = routeshow }

	-- ip rule show
	local ipr = luci.sys.exec("ip rule show")
		ipr = "<br />" .. string.gsub(ipr, "\n", "<br />") .. "<br />"
	rv.iprule = { }
	ipruleid = {}
	ipruleid[ipr] = #rv.iprule + 1
	rv.iprule[ipruleid[ipr]] = { rule = ipr }

	-- ip route list table
	local routelisting = luci.sys.exec("ip rule | awk -F: '{ print $1 }' | awk '$1>=1001 && $1<=1099'")
	local rlstr = ""
		for line in routelisting:gmatch("[^\r\n]+") do
			local rlstr1 = luci.sys.exec("ip route list table " .. line)
			rlstr = rlstr .. line .. "<br />" .. rlstr1
		end
		rlstr = "<br />" .. rlstr .. "<br />"
	rv.routelist = { }
	rtlist = {}
	rtlist[rlstr] = #rv.routelist + 1
	rv.routelist[rtlist[rlstr]] = { iprtlist = rlstr }

	-- iptables
	local iptbl = luci.sys.exec("iptables -L -t mangle -v -n | awk '/mwan3/' RS= | sed -e 's/.*Chain.*/\\n&/'")
		iptbl = string.gsub(iptbl, "\n", "<br />") .. "<br />"
	rv.iptables = { }
	tables = {}
	tables[iptbl] = #rv.iptables + 1
	rv.iptables[tables[iptbl]] = { iptbls = iptbl }

	-- ifconfig
	local ifcg = luci.sys.exec("ifconfig")
		ifcg = "<br />" .. string.gsub(ifcg, "\n", "<br />")
	rv.ifconfig = { }
	icfg = {}
	icfg[ifcg] = #rv.ifconfig + 1
	rv.ifconfig[icfg[ifcg]] = { ifcfg = ifcg }

	-- mwan3 config
	local mwcg = luci.sys.exec("cat /etc/config/mwan3")
		mwcg = string.gsub(mwcg, "\n", "<br />")
	rv.mwan3config = { }
	mwan3cfg = {}
	mwan3cfg[mwcg] = #rv.mwan3config + 1
	rv.mwan3config[mwan3cfg[mwcg]] = { mwn3cfg = mwcg }

	-- network config
	local netcg = luci.sys.exec("cat /etc/config/network")
		netcg = string.gsub(netcg, "\n", "<br />")
	rv.netconfig = { }
	ncfg = {}
	ncfg[netcg] = #rv.netconfig + 1
	rv.netconfig[ncfg[netcg]] = { netcfg = netcg }

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end
