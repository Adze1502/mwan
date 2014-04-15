-- ------ extra functions ------ --

function iface_check() -- find issues with too many interfaces, reliability and metric
	uci.cursor():foreach("mwan3", "interface",
		function (section)
			ifnum = ifnum+1 -- count number of mwan3 interfaces configured
			-- create list of metrics for none and duplicate checking
			local metlkp = ut.trim(sys.exec("uci get -p /var/state network." .. section[".name"] .. ".metric"))
			if metlkp == "" then
				err_nomet_list = err_nomet_list .. section[".name"] .. " "
			else
				metric_list = metric_list .. section[".name"] .. " " .. metlkp .. "\n"
			end
			-- check if any interfaces have a higher reliability requirement than track IPs configured
			local relnum = tonumber(ut.trim(sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".reliability")))
			local tipnum = ut.trim(sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".track_ip"))
			if relnum and tipnum then
				local _, tipnum = string.gsub(tipnum, " ", " ")
				tipnum = tipnum + 1
				if relnum > tipnum then
					err_rel_list = err_rel_list .. section[".name"] .. " "
				end
			end
			-- check if any interfaces are not properly configured in /etc/config/network or have no default route in main routing table
			if ut.trim(sys.exec("uci get -p /var/state network." .. section[".name"])) == "interface" then
				local ifdev = ut.trim(sys.exec("uci get -p /var/state network." .. section[".name"] .. ".ifname"))
				if ifdev == "uci: Entry not found" or ifdev == "" then
					err_netcfg_list = err_netcfg_list .. section[".name"] .. " "
					err_route_list = err_route_list .. section [".name"] .. " "
				else
					local rtcheck = ut.trim(sys.exec("route -n | awk -F' ' '{ if ($8 == \"" .. ifdev .. "\" && $1 == \"0.0.0.0\") print $1 }'"))
					if rtcheck == "" then
						err_route_list = err_route_list .. section [".name"] .. " "
					end
				end
			else
				err_netcfg_list = err_netcfg_list .. section[".name"] .. " "
				err_route_list = err_route_list .. section [".name"] .. " "
			end
		end
	)
	-- check if any interfaces have duplicate metrics
	local metric_dupnums = sys.exec("echo '" .. metric_list .. "' | awk -F' ' '{ print $2 }' | uniq -d")
	local metric_dupes = ""
	for line in metric_dupnums:gmatch("[^\r\n]+") do
		metric_dupes = sys.exec("echo '" .. metric_list .. "' | grep '" .. line .. "' | awk -F' ' '{ print $1 }'")
		err_dupmet_list = err_dupmet_list .. metric_dupes
	end
end

function iface_warn() -- display status and warning messages at the top of the page
	local warns = ""
	if ifnum <= 250 then
		warns = "<strong>There are currently " .. ifnum .. " of 250 supported interfaces configured!</strong>"
	else
		warns = "<font color=\"ff0000\"><strong>WARNING: " .. ifnum .. " interfaces are configured exceeding the maximum of 250!</strong></font>"
	end
	if err_rel_list ~= "" then
		warns = warns .. "<br /><br /><font color=\"ff0000\"><strong>WARNING: some interfaces have a higher reliability requirement than there are test IP addresses!</strong></font>"
	end
	if err_route_list ~= "" then
		warns = warns .. "<br /><br /><font color=\"ff0000\"><strong>WARNING: some interfaces have no default route in the main routing table!</strong></font>"
	end
	if err_netcfg_list ~= "" then
		warns = warns .. "<br /><br /><font color=\"ff0000\"><strong>WARNING: some interfaces are configured incorrectly or not at all in /etc/config/network!</strong></font>"
	end
	if err_nomet_list ~= "" then
		warns = warns .. "<br /><br /><font color=\"ff0000\"><strong>WARNING: some interfaces have no metric configured in /etc/config/network!</strong></font>"
	end
	if err_dupmet_list ~= "" then
		warns = warns .. "<br /><br /><font color=\"ff0000\"><strong>WARNING: some interfaces have duplicate metrics configured in /etc/config/network!</strong></font>"
	end
	return warns
end

-- ------ interface configuration ------ --

dsp = require "luci.dispatcher"
sys = require "luci.sys"
ut = require "luci.util"

ifnum = 0
metric_list = ""
err_dupmet_list = ""
err_netcfg_list = ""
err_nomet_list = ""
err_rel_list = ""
err_route_list = ""
iface_check()


m5 = Map("mwan3", translate("MWAN3 Multi-WAN Interface Configuration"),
	translate(iface_warn()))
	m5:append(Template("mwan3/mwan3_config_css"))


mwan_interface = m5:section(TypedSection, "interface", translate("Interfaces"),
	translate("MWAN3 supports up to 250 physical and/or logical interfaces<br />" ..
	"MWAN3 requires that all interfaces have a unique metric configured in /etc/config/network<br />" ..
	"Names must match the interface name found in /etc/config/network (see advanced tab)<br />" ..
	"Names may contain characters A-Z, a-z, 0-9, _ and no spaces<br />" ..
	"Interfaces may not share the same name as configured members, policies or rules"))
	mwan_interface.addremove = true
	mwan_interface.dynamic = false
	mwan_interface.sectionhead = "Interface"
	mwan_interface.sortable = true
	mwan_interface.template = "cbi/tblsection"
	mwan_interface.extedit = dsp.build_url("admin", "network", "mwan3", "configuration", "interface", "%s")
	function mwan_interface.create(self, section)
		TypedSection.create(self, section)
		m5.uci:save("mwan3")
		luci.http.redirect(dsp.build_url("admin", "network", "mwan3", "configuration", "interface", section))
	end


enabled = mwan_interface:option(DummyValue, "enabled", translate("Enabled"))
	enabled.rawhtml = true
	function enabled.cfgvalue(self, s)
		if self.map:get(s, "enabled") == "1" then
			return "Yes"
		else
			return "No"
		end
	end

track_ip = mwan_interface:option(DummyValue, "track_ip", translate("Test IP"))
	track_ip.rawhtml = true
	function track_ip.cfgvalue(self, s)
		local str = ""
		tracked = self.map:get(s, "track_ip")
		if tracked then
			for k,v in pairs(tracked) do
				str = str .. v .. "<br />"
			end
			return str
		else
			return "<font size=\"+4\">-</font>"
		end
	end

reliability = mwan_interface:option(DummyValue, "reliability", translate("Test IP reliability"))
	reliability.rawhtml = true
	function reliability.cfgvalue(self, s)
		if tracked then
			return self.map:get(s, "reliability") or "<font size=\"+4\">-</font>"
		else
			return "n/a"
		end
	end

count = mwan_interface:option(DummyValue, "count", translate("Ping count"))
	count.rawhtml = true
	function count.cfgvalue(self, s)
		if tracked then
			return self.map:get(s, "count") or "<font size=\"+4\">-</font>"
		else
			return "n/a"
		end
	end

timeout = mwan_interface:option(DummyValue, "timeout", translate("Ping timeout"))
	timeout.rawhtml = true
	function timeout.cfgvalue(self, s)
		if tracked then
			local tcheck = self.map:get(s, "timeout")
			if tcheck then
				return tcheck .. "s"
			else
				return "<font size=\"+4\">-</font>"
			end
		else
			return "n/a"
		end
	end

interval = mwan_interface:option(DummyValue, "interval", translate("Ping interval"))
	interval.rawhtml = true
	function interval.cfgvalue(self, s)
		if tracked then
			local icheck = self.map:get(s, "interval")
			if icheck then
				return icheck .. "s"
			else
				return "<font size=\"+4\">-</font>"
			end
		else
			return "n/a"
		end
	end

down = mwan_interface:option(DummyValue, "down", translate("Interface down"))
	down.rawhtml = true
	function down.cfgvalue(self, s)
		if tracked then
			return self.map:get(s, "down") or "<font size=\"+4\">-</font>"
		else
			return "n/a"
		end
	end

up = mwan_interface:option(DummyValue, "up", translate("Interface up"))
	up.rawhtml = true
	function up.cfgvalue(self, s)
		if tracked then
			return self.map:get(s, "up") or "<font size=\"+4\">-</font>"
		else
			return "n/a"
		end
	end

metric = mwan_interface:option(DummyValue, "metric", translate("Metric"))
	metric.rawhtml = true
	function metric.cfgvalue(self, s)
		local metcheck = ut.trim(sys.exec("uci get -p /var/state network." .. s .. ".metric"))
		if metcheck ~= "" then
			return metcheck
		else
			return "<font size=\"+4\">-</font>"
		end
	end

errors = mwan_interface:option(DummyValue, "errors", translate("Errors"))
	errors.rawhtml = true
	function errors.cfgvalue(self, s)
		local mouseover = ""
		local linebrk = ""
		if sys.exec("echo '" .. err_rel_list .. "' | grep -w " .. s) ~= "" then
			mouseover = "Higher reliability requirement than there are test IP addresses"
			linebrk = "&#10;&#10;"
		end
		if sys.exec("echo '" .. err_route_list .. "' | grep -w " .. s) ~= "" then
			mouseover = mouseover .. linebrk .. "No default route in the main routing table"
			linebrk = "&#10;&#10;"
		end
		if sys.exec("echo '" .. err_netcfg_list .. "' | grep -w " .. s) ~= "" then
			mouseover = mouseover .. linebrk .. "Configured incorrectly or not at all in /etc/config/network"
			linebrk = "&#10;&#10;"
		end
		if sys.exec("echo '" .. err_nomet_list .. "' | grep -w " .. s) ~= "" then
			mouseover = mouseover .. linebrk .. "No metric configured in /etc/config/network"
			linebrk = "&#10;&#10;"
		end
		if sys.exec("echo '" .. err_dupmet_list .. "' | grep -w " .. s) ~= "" then
			mouseover = mouseover .. linebrk .. "Duplicate metric configured in /etc/config/network"
		end
		if mouseover == "" then
			return mouseover
		else
			return "<span title=\"" .. mouseover .. "\"><img src=\"/luci-static/resources/cbi/reset.gif\" alt=\"error\"></img></span>"
		end
	end


return m5
