local serialize = {}

--Pack table into string
function serialize.pack(t)
	local tStr = "{"
	local lastNumKey = 0
	for k, v in pairs(t) do
		--Val
		local valType = type(v)
		local valStr = nil

		if valType == "string" then
			valStr = '"'..v..'"'
		elseif valType == "number" or valType == "boolean" then
			valStr = tostring(v)
		elseif valType == "table" then
			valStr = serialize.pack(v)
		end

		--Pair
		if valStr then
			local keyStr = k.."="

			if type(k) == "number" then
				if k == lastNumKey + 1 then
					keyStr = ""
					lastNumKey = k
				else
					keyStr = "["..k.."]="
					lastNumKey = k
				end
			end

			tStr = tStr..keyStr..valStr..","
		end
	end
	local len = #tStr
	if len > 1 then tStr = tStr:sub(1, len - 1) end
	return tStr.."}"
end

--Unpack string back to table
function serialize.unpack(tStr)
	return loadstring("return "..tStr)()
end

return serialize
