local dsp = require "luci.dispatcher"

arg[1] = arg[1] or ""

function ifacewarn()
	local warns = ""
	local metcheck = luci.sys.exec("uci get -p /var/state network." .. arg[1] .. ".metric")
	if string.len(metcheck) == 0 then
		warns = "<font color=\"ff0000\"><strong><em>WARNING: this interface has no metric configured in /etc/config/network!</em></strong></font>"
	else
		metcheck = string.gsub(metcheck, "\n", "")
		if metrichighlight(metcheck) == "dup" then
			warns = "<font color=\"ff0000\"><strong><em>WARNING: this and other interfaces have duplicate metrics configured in /etc/config/network!</em></strong></font>"
		end
	end
	return warns
end

function metrichighlight(sysmet)
	local dupmet = ""
	uci.cursor():foreach("mwan3", "interface",
		function (section)
			local metcheck = luci.sys.exec("uci get -p /var/state network." .. section[".name"] .. ".metric")
			if string.len(metcheck) > 0 then
				dupmet = dupmet .. " " .. metcheck
			end
		end
	)
	dupmet = luci.sys.exec("echo \"" .. dupmet .. "\" | sed 's/^[ \t]*//;s/[ \t]*$//' | tr \" \" \"\n\" | grep \"" .. sysmet .. "\" | uniq -c | grep -v \" 1 \"")
	if string.len(dupmet) > 0 then
		return "dup"
	end
end

-- ------ interface configuration ------ --

m5 = Map("mwan3", translate("MWAN3 Multi-WAN Interface Configuration - " .. arg[1]),
	translate(ifacewarn()))

	m5.redirect = dsp.build_url("admin", "network", "mwan3", "interface")

	if not m5.uci:get(arg[1]) == "interface" then
		luci.http.redirect(m5.redirect)
		return
	end


mwan_interface = m5:section(NamedSection, arg[1], "interface", "")
	mwan_interface.addremove = false
	mwan_interface.dynamic = false


enabled = mwan_interface:option(ListValue, "enabled", translate("Enabled"))
	enabled.default = "1"
	enabled:value("1", translate("Yes"))
	enabled:value("0", translate("No"))

track_ip = mwan_interface:option(DynamicList, "track_ip", translate("Test IP"),
	translate("This IP address will be pinged to dermine if the link is up or down"))
	track_ip.datatype = "ipaddr"

reliability = mwan_interface:option(Value, "reliability", translate("Test IP reliability"),
	translate("This many Test IP addresses must respond for the link to be deemed up"),
	translate("Do not specify a number higher than the ammount of Test IP addresses you have configured"),
	translate("Acceptable values: 1-1000"))
	reliability.datatype = "range(1, 1000)"
	reliability.default = "1"

count = mwan_interface:option(ListValue, "count", translate("Ping count"))
	count.default = "1"
	count:value("1")
	count:value("2")
	count:value("3")
	count:value("4")
	count:value("5")

timeout = mwan_interface:option(ListValue, "timeout", translate("Ping timeout"))
	timeout.default = "2"
	timeout:value("1", translate("1 second"))
	timeout:value("2", translate("2 seconds"))
	timeout:value("3", translate("3 seconds"))
	timeout:value("4", translate("4 seconds"))
	timeout:value("5", translate("5 seconds"))

interval = mwan_interface:option(ListValue, "interval", translate("Ping interval"))
	interval.default = "5"
	interval:value("1", translate("1 second"))
	interval:value("3", translate("3 seconds"))
	interval:value("5", translate("5 seconds"))
	interval:value("10", translate("10 seconds"))
	interval:value("20", translate("20 seconds"))
	interval:value("30", translate("30 seconds"))
	interval:value("60", translate("60 seconds"))

down = mwan_interface:option(ListValue, "down", translate("Interface down"),
	translate("Interface will be deemed down after this many failed ping tests"))
	down.default = "3"
	down:value("1")
	down:value("2")
	down:value("3")
	down:value("4")
	down:value("5")
	down:value("6")
	down:value("7")
	down:value("8")
	down:value("9")
	down:value("10")

up = mwan_interface:option(ListValue, "up", translate("Interface up"),
	translate("Downed interface will be deemed up after this many successful ping tests"))
	up.default = "3"
	up:value("1")
	up:value("2")
	up:value("3")
	up:value("4")
	up:value("5")
	up:value("6")
	up:value("7")
	up:value("8")
	up:value("9")
	up:value("10")

metric = mwan_interface:option(DummyValue, "metric", translate("Metric"),
	translate("This displays the metric assigned to this interface in /etc/config/network<br />"))
	metric.rawhtml = true
	function metric.cfgvalue(self, s)
		local metcheck = luci.sys.exec("uci get -p /var/state network." .. s .. ".metric")
		if string.len(metcheck) > 0 then
			metcheck = string.gsub(metcheck, "\n", "")
			if metrichighlight(metcheck) == "dup" then
				metcheck = "<font color=\"ff0000\"><strong>" .. metcheck .. "</strong></font>"
			end
		else
			metcheck = "<font color=\"ff0000\"><font size=\"+4\">-</font></font>"
		end
		return metcheck
	end


return m5
