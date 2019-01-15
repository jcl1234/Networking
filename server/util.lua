--Copy table
function copy(t)
	if type(t) ~= "table" or t == {} then return t end
	local new = {}
	for k,v in pairs(t) do
		new[k] = copy(v)
	end
	return new
end