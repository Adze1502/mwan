module("luci.controller.mwan3", package.seeall)

ntm = require "luci.model.network".init()
sys = require "luci.sys"
ut = require "luci.util"

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
		template("mwan3/mwan3_overview"),
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

	entry({"admin", "network", "mwan3", "advanced"},
		call("mwan3_advanced"),
		_("Advanced"), 100)
	entry({"admin", "network", "mwan3", "advanced", "hotplug"},
		form("mwan3/mwan3_adv_hotplug"))
	entry({"admin", "network", "mwan3", "advanced", "mwan3"},
		form("mwan3/mwan3_adv_mwan3"))
	entry({"admin", "network", "mwan3", "advanced", "network"},
		form("mwan3/mwan3_adv_network"))
	entry({"admin", "network", "mwan3", "advanced", "startup"},
		form("mwan3/mwan3_adv_startup"))
end

function mwan3_get_status(rulenum, ifname)
	if ut.trim(sys.exec("uci get -p /var/state mwan3." .. ifname .. ".enabled")) == "1" then
		if string.len(sys.exec("ip route list table " .. rulenum)) > 0 then
			if string.len(sys.exec("uci get -p /var/state mwan3." .. ifname .. ".track_ip")) > 0 then
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
	local rv = {	}

	-- overview status
	local statstr = mwan3_get_iface()
	if string.len(statstr) > 0 then
		rv.wans = { }
		wansid = {}

		for wanname, ifstat in string.gfind(statstr, "([^%[]+)%[([^%]]+)%]") do
			local wanifname = ut.trim(sys.exec("uci get -p /var/state network." .. wanname .. ".ifname"))
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
	local mwlg = ut.trim(sys.exec("logread | grep mwan3 | tail -n 50 | sed 'x;1!H;$!d;x'"))
	if string.len(mwlg) > 0 then
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

	-- software versions
	local wrtrelease = luci.version.distversion
		local wrtrev = ut.trim(sys.exec("cat /etc/openwrt_release | grep REVISION | awk -F'\"' '{print $2}'"))
		if string.len(wrtrelease) > 0 then
			if string.len(wrtrev) > 0 then
				wrtrelease = "<br />OpenWrt - " .. wrtrelease .. " (" .. wrtrev .. ")"
			else
				wrtrelease = "<br />OpenWrt - " .. wrtrelease
			end
		elseif string.len(wrtrev) > 0 then
			wrtrelease = "<br />OpenWrt - " .. wrtrev
		else
			wrtrelease = "<br />OpenWrt - unknown"
		end
	local mwan3version = ut.trim(sys.exec("opkg info mwan3 | grep Version | awk -F' ' '{ print $2 }'"))
		if string.len(mwan3version) > 0 then
			mwan3version = "<br />mwan3 - " .. mwan3version
		else
			mwan3version = "<br />mwan3 - unknown"
		end
	local mwan3lversion = ut.trim(sys.exec("opkg info luci-app-mwan3 | grep Version | awk -F' ' '{ print $2 }'"))
		if string.len(mwan3lversion) > 0 then
			mwan3lversion = "<br />luci-app-mwan3 - " .. mwan3lversion
		else
			mwan3lversion = "<br />luci-app-mwan3 - unknown<br /><br />"
		end
	local softrev = ut.trim(wrtrelease .. mwan3version .. mwan3lversion)
	rv.mw3ver = { }
	mwv = {}
	mwv[softrev] = #rv.mw3ver + 1
	rv.mw3ver[mwv[softrev]] = { mwan3v = softrev }

	-- default firewall output policy
	local defout = ut.trim(sys.exec("uci get -p /var/state firewall.@defaults[0].output"))
		if string.len(defout) == 0 then
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
	local routelisting = sys.exec("ip rule | awk -F: '{ print $1 }' | awk '$1>=1001 && $1<=1099'")
	local rlstr = ""
		if string.len(routelisting) > 0 then
			for line in routelisting:gmatch("[^\r\n]+") do
				rlstr = rlstr .. line .. "<br />" .. sys.exec("ip route list table " .. line)
			end
		else
			rlstr = "No data found<br />"
		end
	rv.routelist = { }
	rtlist = {}
	rtlist[rlstr] = #rv.routelist + 1
	rv.routelist[rtlist[rlstr]] = { iprtlist = rlstr }

	-- iptables
	local iptbl = ut.trim(sys.exec("iptables -L -t mangle -v -n | awk '/mwan3/' RS= | sed -e 's/.*Chain.*/\\n&/'"))
		if string.len(iptbl) == 0 then
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
		if ut.trim(sys.exec("echo \"" .. mwcg .. "\" | sed 's/<br \\/>//g'")) == "" then
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

function mwan3_advanced()
	luci.template.render("mwan3/mwan3_adv_troubleshoot")
end
