function string:split_b(sep)
	local cuts = {}
	for v in string.gmatch(self, "[^'" .. sep .. "']+") do
		table.insert(cuts,v)
	end

	return cuts
end
