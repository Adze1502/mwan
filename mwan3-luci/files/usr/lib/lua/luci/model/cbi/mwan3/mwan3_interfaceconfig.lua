-- ------ extra functions ------ --

function metric_list()
	metcheck = ut.trim(sys.exec("uci get -p /var/state network." .. arg[1] .. ".metric"))
	if metcheck == "" then -- no metric
		metnone = 1
	else -- if metric exists create list of interface metrics to compare against for duplicates
		uci.cursor():foreach("mwan3", "interface",
			function (section)
				local metlkp = ut.trim(sys.exec("uci get -p /var/state network." .. section[".name"] .. ".metric"))
				if metlkp == "" then
					metlkp = "none"
				end
				metlst = metlst .. metlkp .. " "
			end
		)
		metlst = ut.trim(sys.exec("echo '" .. metlst .. "' | sed 's/ *$//' | tr ' ' '\n'"))
		-- compare metric against list
		if ut.trim(sys.exec("echo '" .. metlst .. "' | grep -c -w '" .. metcheck .. "'")) ~= "1" then
			metdup = 1
		end
	end
end

function iface_warn() -- display warning messages at the top of the page
	if metnone == 1 then
		return "<font color=\"ff0000\"><strong><em>WARNING: this interface has no metric configured in /etc/config/network!</em></strong></font>"
	elseif metdup == 1 then
		return "<font color=\"ff0000\"><strong><em>WARNING: this and other interfaces have duplicate metrics configured in /etc/config/network!</em></strong></font>"
	else
		return ""
	end
end

-- ------ interface configuration ------ --

dsp = require "luci.dispatcher"
sys = require "luci.sys"
ut = require "luci.util"
arg[1] = arg[1] or ""

metlst = ""
metcheck = ""
metnone = 0
metdup = 0
metric_list()


m5 = Map("mwan3", translate("MWAN3 Multi-WAN Interface Configuration - " .. arg[1]),
	translate(iface_warn()))
	m5.redirect = dsp.build_url("admin", "network", "mwan3", "interface")


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
	timeout:value("6", translate("6 seconds"))
	timeout:value("7", translate("7 seconds"))
	timeout:value("8", translate("8 seconds"))
	timeout:value("9", translate("9 seconds"))
	timeout:value("10", translate("10 seconds"))

interval = mwan_interface:option(ListValue, "interval", translate("Ping interval"))
	interval.default = "5"
	interval:value("1", translate("1 second"))
	interval:value("3", translate("3 seconds"))
	interval:value("5", translate("5 seconds"))
	interval:value("10", translate("10 seconds"))
	interval:value("20", translate("20 seconds"))
	interval:value("30", translate("30 seconds"))
	interval:value("60", translate("1 minute"))
	interval:value("300", translate("5 minutes"))
	interval:value("600", translate("10 minutes"))
	interval:value("900", translate("15 minutes"))
	interval:value("1800", translate("30 minutes"))
	interval:value("3600", translate("1 hour"))

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
	up.default = "5"
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
		if metnone == 1 then -- no metric
			return "<font color=\"ff0000\"><font size=\"+4\">-</font></font>"
		elseif metdup == 1 then -- metric is a duplicate
			return "<font color=\"ff0000\"><strong>" .. metcheck .. "</strong></font>"
		else
			return metcheck
		end
	end


return m5
