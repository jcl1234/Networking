function removeFirst(t, num)
	local kShift = 0
	for i=1, num do
		table.remove(t, i-kShift)
		kShift = kShift + 1
	end
end

function factorTable(t, factor)
	if type(t) ~= "table" then return t * factor end
	local facT = {}
	for k, v in pairs(t) do
		facT[k] = factorTable(v, factor)
	end
	return facT
end