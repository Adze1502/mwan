-- ------ extra functions ------ --

function trailtrim(s)
	local n = #s
	while n > 0 and s:find("^%s", n) do n = n - 1 end
	return s:sub(1, n)
end

-- ------ mwan3 configuration ------ --

local mwan3file = "/etc/config/mwan3"

m = SimpleForm("luci", nil)
	m:append(Template("mwan3/mwan3_adv_mwan3"))


f = m:section(SimpleSection, nil,
	translate("<br />This section allows you to modify the contents of /etc/config/mwan3<br /><br />"))

t = f:option(TextValue, "lines")
	t.rmempty = true
	t.rows = 20

	function t.cfgvalue()
		return nixio.fs.readfile(mwan3file) or ""
	end

	function t.write(self, section, data)
		return nixio.fs.writefile(mwan3file, "\n" .. trailtrim(data:gsub("\r\n", "\n")) .. "\n")
	end

	function f.handle(self, state, data)
		return true
	end


return m
