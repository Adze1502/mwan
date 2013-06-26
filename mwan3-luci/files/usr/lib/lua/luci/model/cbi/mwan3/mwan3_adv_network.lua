-- ------ extra functions ------ --

function leadtrailtrim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- ------ network configuration ------ --

local netfile = "/etc/config/network"

m = SimpleForm("networkconf", nil)
	m:append(Template("mwan3/mwan3_adv_network"))


f = m:section(SimpleSection, nil,
	translate("<br />This section allows you to modify the contents of /etc/config/network<br /><br />"))

t = f:option(TextValue, "lines")
	t.rmempty = true
	t.rows = 20

	function t.cfgvalue()
		return nixio.fs.readfile(netfile) or ""
	end

	function t.write(self, section, data)
		return nixio.fs.writefile(netfile, "\n" .. leadtrailtrim(data:gsub("\r\n", "\n")) .. "\n")
	end

	function f.handle(self, state, data)
		return true
	end


return m
