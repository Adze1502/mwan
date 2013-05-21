local dsp = require "luci.dispatcher"

arg[1] = arg[1] or ""

-- ------ interface configuration ------ --

m30 = Map("mwan3", translate("MWAN3 Multi-WAN interface configuration - ") .. arg[1])

	m30.redirect = dsp.build_url("admin", "network", "mwan3", "interface")

	if not m30.uci:get(arg[1]) == "interface" then
		luci.http.redirect(m30.redirect)
		return
	end


mwan_interface = m30:section(NamedSection, arg[1], "interface", "")
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


return m30
