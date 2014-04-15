module("luci.controller.mwan3", package.seeall)

sys = require "luci.sys"
ut = require "luci.util"

function index()
	if not nixio.fs.access("/etc/config/mwan3") then
		return
	end

	entry({"admin", "network", "mwan3"},
		alias("admin", "network", "mwan3", "overview"),
		_("Load Balancing"), 600)

	entry({"admin", "network", "mwan3", "overview"},
		alias("admin", "network", "mwan3", "overview", "over_iface"),
		_("Overview"), 10)
	entry({"admin", "network", "mwan3", "overview", "over_iface"},
		template("mwan3/mwan3_over_interface"))
	entry({"admin", "network", "mwan3", "overview", "iface_status"},
		call("mwan3_iface_status"))
	entry({"admin", "network", "mwan3", "overview", "over_policy"},
		template("mwan3/mwan3_over_policy"))
	entry({"admin", "network", "mwan3", "overview", "policy_status"},
		call("mwan3_policy_status"))
	entry({"admin", "network", "mwan3", "overview", "over_rule"},
		template("mwan3/mwan3_over_rule"))
	entry({"admin", "network", "mwan3", "overview", "rule_status"},
		call("mwan3_rule_status"))

	entry({"admin", "network", "mwan3", "configuration"},
		alias("admin", "network", "mwan3", "configuration", "interface"),
		_("Configuration"), 20)
	entry({"admin", "network", "mwan3", "configuration", "interface"},
		arcombine(cbi("mwan3/mwan3_interface"), cbi("mwan3/mwan3_interfaceconfig")),
		_("Interfaces"), 10).leaf = true
	entry({"admin", "network", "mwan3", "configuration", "member"},
		arcombine(cbi("mwan3/mwan3_member"), cbi("mwan3/mwan3_memberconfig")),
		_("Members"), 20).leaf = true
	entry({"admin", "network", "mwan3", "configuration", "policy"},
		arcombine(cbi("mwan3/mwan3_policy"), cbi("mwan3/mwan3_policyconfig")),
		_("Policies"), 30).leaf = true
	entry({"admin", "network", "mwan3", "configuration", "rule"},
		arcombine(cbi("mwan3/mwan3_rule"), cbi("mwan3/mwan3_ruleconfig")),
		_("Rules"), 40).leaf = true

	entry({"admin", "network", "mwan3", "advanced"},
		alias("admin", "network", "mwan3", "advanced", "hotplug"),
		_("Advanced"), 100)
	entry({"admin", "network", "mwan3", "advanced", "hotplug"},
		form("mwan3/mwan3_adv_hotplug"))
	entry({"admin", "network", "mwan3", "advanced", "mwan3"},
		form("mwan3/mwan3_adv_mwan3"))
	entry({"admin", "network", "mwan3", "advanced", "network"},
		form("mwan3/mwan3_adv_network"))
	entry({"admin", "network", "mwan3", "advanced", "tshoot"},
		template("mwan3/mwan3_adv_troubleshoot"))
	entry({"admin", "network", "mwan3", "advanced", "tshoot_display"},
		call("mwan3_tshoot_data"))
end

function mwan3_get_iface_status(rulenum, ifname)
	if ut.trim(sys.exec("uci get -p /var/state mwan3." .. ifname .. ".enabled")) == "1" then
		if ut.trim(sys.exec("ip route list table " .. rulenum)) ~= "" then
			if ut.trim(sys.exec("uci get -p /var/state mwan3." .. ifname .. ".track_ip")) ~= "" then
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
	local rulenum = 0
	uci.cursor():foreach("mwan3", "interface",
		function (section)
			rulenum = rulenum+1
			str = str .. section[".name"] .. "[" .. mwan3_get_iface_status(rulenum, section[".name"]) .. "]"
		end
	)
	return str
end

function mwan3_iface_status()
	local ntm = require "luci.model.network".init()

	local rv = {	}

	-- overview status
	local statstr = mwan3_get_iface()
	if statstr ~= "" then
		rv.wans = { }
		wansid = {}

		for wanname, ifstat in string.gfind(statstr, "([^%[]+)%[([^%]]+)%]") do
			local wanifname = ut.trim(sys.exec("uci get -p /var/state network." .. wanname .. ".ifname"))
				if wanifname == "" then
					wanifname = "X"
				end
			local wanlink = ntm:get_interface(wanifname)
				wanlink = wanlink and wanlink:get_network()
				wanlink = wanlink and wanlink:adminlink() or "#"
			wansid[wanname] = #rv.wans + 1
			rv.wans[wansid[wanname]] = { name = wanname, link = wanlink, ifname = wanifname, status = ifstat }
		end
	end

	-- overview status log
	local mwlg = ut.trim(sys.exec("logread | grep mwan3 | tail -n 50 | sed 'x;1!H;$!d;x'"))
	if mwlg ~= "" then
		rv.mwan3log = { }
		mwlog = {}
		mwlog[mwlg] = #rv.mwan3log + 1
		rv.mwan3log[mwlog[mwlg]] = { mwanlog = mwlg }
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function mwan3_policy_status()
	local rv = {	}

	-- policy status
	local pst = ut.trim(sys.exec("mwan3 policies"))
	if pst ~= "" then
		rv.mwan3pst = { }
		plstat = {}
		plstat[pst] = #rv.mwan3pst + 1
		rv.mwan3pst[plstat[pst]] = { polstat = pst }
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function mwan3_rule_status()
	local rv = {	}

	-- rule status
	local rst = ut.trim(sys.exec("mwan3 rules"))
	if rst ~= "" then
		rv.mwan3rst = { }
		rlst = {}
		rlst[rst] = #rv.mwan3rst + 1
		rv.mwan3rst[rlst[rst]] = { rulestat = rst }
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function mwan3_tshoot_data()
	local rv = {	}

	-- software versions
	local wrtrelease = ut.trim(luci.version.distversion)
		if wrtrelease ~= "" then
			wrtrelease = "OpenWrt - " .. wrtrelease
		else
			wrtrelease = "OpenWrt - unknown"
		end
	local lucirelease = ut.trim(luci.version.luciversion)
		if lucirelease ~= "" then
			lucirelease = "\nLuCI - " .. lucirelease
		else
			lucirelease = "\nLuCI - unknown"
		end
	local mwan3version = ut.trim(sys.exec("opkg info mwan3 | grep Version | awk -F' ' '{ print $2 }'"))
		if mwan3version ~= "" then
			mwan3version = "\n\nmwan3 - " .. mwan3version
		else
			mwan3version = "\nmwan3 - unknown"
		end
	local mwan3lversion = ut.trim(sys.exec("opkg info luci-app-mwan3 | grep Version | awk -F' ' '{ print $2 }'"))
		if mwan3lversion ~= "" then
			mwan3lversion = "\nluci-app-mwan3 - " .. mwan3lversion
		else
			mwan3lversion = "\nluci-app-mwan3 - unknown"
		end
	local softrev = wrtrelease .. lucirelease .. mwan3version .. mwan3lversion
	rv.mw3ver = { }
	mwv = {}
	mwv[softrev] = #rv.mw3ver + 1
	rv.mw3ver[mwv[softrev]] = { mwan3v = softrev }

	-- default firewall output policy
	local defout = ut.trim(sys.exec("uci get -p /var/state firewall.@defaults[0].output"))
		if defout == "" then
			defout = "No data found"
		end
	rv.fidef = { }
	fwdf = {}
	fwdf[defout] = #rv.fidef + 1
	rv.fidef[fwdf[defout]] = { firedef = defout }

	-- ip route show
	local routeshow = ut.trim(sys.exec("ip route show"))
	rv.rtshow = { }
	rshw = {}
	rshw[routeshow] = #rv.rtshow + 1
	rv.rtshow[rshw[routeshow]] = { iprtshow = routeshow }

	-- ip rule show
	local ipr = ut.trim(sys.exec("ip rule show"))
	rv.iprule = { }
	ipruleid = {}
	ipruleid[ipr] = #rv.iprule + 1
	rv.iprule[ipruleid[ipr]] = { rule = ipr }

	-- ip route list table
	local routelisting = ut.trim(sys.exec("ip rule | sed 's/://g' | awk -F' ' '$1>=2001 && $1<=2250' | awk -F' ' '{ print $NF }'"))
	local rlstr = "main\n" .. sys.exec("ip route list table main")
		if routelisting ~= "" then
			for line in routelisting:gmatch("[^\r\n]+") do
				rlstr = rlstr .. line .. "\n" .. sys.exec("ip route list table " .. line)
			end
			rlstr = ut.trim(rlstr)
		else
			rlstr = "No data found"
		end
	rv.routelist = { }
	rtlist = {}
	rtlist[rlstr] = #rv.routelist + 1
	rv.routelist[rtlist[rlstr]] = { iprtlist = rlstr }

	-- iptables
	local iptbl = ut.trim(sys.exec("iptables -L -t mangle -v -n"))
		if iptbl == "" then
			iptbl = "No data found"
		end
	rv.iptables = { }
	tables = {}
	tables[iptbl] = #rv.iptables + 1
	rv.iptables[tables[iptbl]] = { iptbls = iptbl }

	-- ifconfig
	local ifcg = ut.trim(sys.exec("ifconfig"))
	rv.ifconfig = { }
	icfg = {}
	icfg[ifcg] = #rv.ifconfig + 1
	rv.ifconfig[icfg[ifcg]] = { ifcfg = ifcg }

	-- mwan3 config
	local mwcg = ut.trim(sys.exec("cat /etc/config/mwan3"))
		if mwcg == "" then
			mwcg = "No data found"
		end
	rv.mwan3config = { }
	mwan3cfg = {}
	mwan3cfg[mwcg] = #rv.mwan3config + 1
	rv.mwan3config[mwan3cfg[mwcg]] = { mwn3cfg = mwcg }

	-- network config
	local netcg = ut.trim(sys.exec("cat /etc/config/network | sed -e 's/.*username.*/	USERNAME HIDDEN/' -e 's/.*password.*/	PASSWORD HIDDEN/'"))
	rv.netconfig = { }
	ncfg = {}
	ncfg[netcg] = #rv.netconfig + 1
	rv.netconfig[ncfg[netcg]] = { netcfg = netcg }

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end
