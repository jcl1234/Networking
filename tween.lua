local tween = {}
tween.tweens = {}

--Copy table
local function copy(t)
	if type(t) ~= "table" or t == {} then return t end
	local new = {}
	for k,v in pairs(t) do
		new[k] = copy(v)
	end
	return new
end

function tween.new(time, startT, endT)
	local t = {}
	t.time = time
	t.timeLeft = time

	t.vals = startT
	t.origVals = copy(t.vals)
	t.endVals = endT

	table.insert(tween.tweens, t)
	return t
end

function tween.update(dt)
	for k, tw in pairs(tween.tweens) do
		tw.timeLeft = tw.timeLeft - dt
		for k, v in pairs(tw.vals) do
			if tw.timeLeft <= 0 then
				tw.vals[k] = tw.endVals[k]
			else
				local dif = tw.endVals[k] - tw.origVals[k]
				local newVal = tw.vals[k] + (dif/tw.time)*dt
				tw.vals[k] = newVal
			end
		end
		if tw.timeLeft <= 0 then
			tween.tweens[k] = nil
		end
	end
end

return tween