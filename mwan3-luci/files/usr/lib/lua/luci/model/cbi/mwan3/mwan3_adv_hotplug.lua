-- ------ extra functions ------ --

function trailtrim(s)
	local n = #s
	while n > 0 and s:find("^%s", n) do n = n - 1 end
	return s:sub(1, n)
end

-- ------ hotplug script configuration ------ --

fs = require "nixio.fs"
script = "/etc/hotplug.d/iface/16-mwan3custom"
scriptbak = "/etc/hotplug.d/iface/16-mwan3custombak"

if luci.http.formvalue("cbid.luci.1._restorebak") then
	luci.http.redirect(luci.dispatcher.build_url("admin/network/mwan3/advanced/hotplug") .. "?restore=yes")
elseif luci.http.formvalue("restore") == "yes" then
	luci.sys.exec("cp -f " .. scriptbak .. " " .. script)
end

m = SimpleForm("luci", nil)
	m:append(Template("mwan3/mwan3_adv_hotplug"))

f = m:section(SimpleSection, nil,
	translate("<br />This section allows you to modify the contents of /etc/hotplug.d/iface/16-mwan3custom<br />" ..
	"This is useful for running system commands and/or scripts based on interface ifup or ifdown hotplug events<br /><br />" ..
	"Notes:<br />" ..
	"The first line of the script must be &#34;#!/bin/sh&#34; without quotes<br />" ..
	"Lines beginning with # are comments and are not executed<br /><br />" ..
	"Available variables:<br />" ..
	"$ACTION is the hotplug event (ifup, ifdown)<br />" ..
	"$INTERFACE is the interface name (wan1, wan2, etc.)<br />" ..
	"$DEVICE is the device name attached to the interface (eth0.1, eth1, etc.)<br /><br />"))


restore = f:option(Button, "_restorebak", translate("Restore default hotplug script"))
	restore.inputtitle = translate("Restore...")
	restore.inputstyle = "apply"

t = f:option(TextValue, "lines")
	t.rmempty = true
	t.rows = 20

	function t.cfgvalue()
		local hps = fs.readfile(script)
		if not hps or hps == "" then -- if script does not exist or is blank restore default
			luci.sys.exec("cp -f " .. scriptbak .. " " .. script)
			return fs.readfile(script)
		else
			return hps
		end
	end

	function t.write(self, section, data)
		return fs.writefile(script, trailtrim(data:gsub("\r\n", "\n")) .. "\n")
	end


return m
