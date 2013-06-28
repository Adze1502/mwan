-- ------ network configuration ------ --

ut = require "luci.util"

netfile = "/etc/config/network"

m = SimpleForm("networkconf", nil)
	m:append(Template("mwan3/mwan3_adv_network"))


f = m:section(SimpleSection, nil,
	translate("<br />This section allows you to modify the contents of /etc/config/network<br /><br />" ..
	"To allow MWAN3 control of router-generated traffic you must complete the following three steps:<br /><br />" ..
	"1. Create a loopback alias config section in /etc/config/network<br /><br />" ..
	"config alias<br />" ..
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;option interface &#39;loopback&#39;<br />" ..
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;option proto &#39;static&#39;<br />" ..
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;option ipaddr &#39;192.168.100.1&#39;<br />" ..
	"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;option netmask &#39;255.255.255.255&#39;<br /><br />" ..
	"The ipaddr option must be an IP address from an unused network in these ranges: 10.x.x.x, 172.16.x.x-172.31.255.255, 192.168.x.x<br /><br />" ..
	"2. Add a default route command to the startup commands tab<br /><br />" ..
	"ip route add default via 127.0.0.1 dev lo src 192.168.100.1 metric 5<br /><br />" ..
	"Configure the source using the IP address from the loopback alias<br />" ..
	"The metric must be lower than any interface metric in /etc/config/network<br /><br />" ..
	"3. Create your desired MWAN3 rules for router-generated traffic with the source address set to the loopback alias IP address<br /><br />"))

t = f:option(TextValue, "lines")
	t.rmempty = true
	t.rows = 20

	function t.cfgvalue()
		return nixio.fs.readfile(netfile) or ""
	end

	function t.write(self, section, data)
		return nixio.fs.writefile(netfile, "\n" .. ut.trim(data:gsub("\r\n", "\n")) .. "\n")
	end

	function f.handle(self, state, data)
		return true
	end


return m
