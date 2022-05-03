local p = require("persistence")
local md5 = require("md5")

local l = {
	data = nil
}

function l.add(filename, line, description)
	local id = md5.sumhexa(string.format("%s:%s", filename, line))
	if l.data[id] ~= nil then --update description
		if description ~= nil then
			l.data[id].description = description
		end
	else -- new
		l.data[id] = {
			filename = filename,
			line = line,
			description = description or ""
		}
	end

	p.add_or_update()
end

function l.delete(id)

end

function l.list(order)

end

return l
