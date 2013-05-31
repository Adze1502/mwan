-- ------ extra functions ------ --

function trailtrim(s)
	local n = #s
	while n > 0 and s:find("^%s", n) do n = n - 1 end
	return s:sub(1, n)
end

-- ------ hotplug script configuration ------ --

local fs = require "nixio.fs"
local hpscript = "/etc/hotplug.d/iface/16-mwan3custom"


f = SimpleForm("mwanhotplug", translate("Custom Hotplug Script Configuration"),
	translate("This section allows you to modify the contents of /etc/hotplug.d/iface/16-mwan3custom<br />") ..
	translate("This is useful for running system commands and/or scripts based on interface ifup or ifdown hotplug events"))


t = f:field(TextValue, "mwhp")
t.rmempty = true
t.rows = 20
function t.cfgvalue()
	return fs.readfile(hpscript) or ""
end

function f.handle(self, state, data)
	if state == FORM_VALID then
		if data.mwhp then
			fs.writefile(hpscript, trailtrim(data.mwhp:gsub("\r\n", "\n")) .. "\n")
		else
			fs.writefile(hpscript, "")
		end
	end
	return true
end


return f
