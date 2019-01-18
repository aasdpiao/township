local class = require "class"
local random_weight = require "random.random_const"

local RandomManager = class()

function RandomManager:ctor()
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
end

function RandomManager:get_random_weight(weight,times)
    assert(weight>0 && weight < 100)
    local fix_weight = random_weight[math.ceil(weight)]
    return fix_weight * times
end

function RandomManager:check_random_weight(weight,times)
    local fix_weight = self.get_random_weight(weight,times)
    local random_value = self.get_random_int(1,100)
    return random_value <= fix_weight
end

function RandomManager:get_random_value_in_weight(total_weight, value_weight_list)
	if total_weight == 0 or #value_weight_list == 0 then
		return nil
	end
	local random_weight = math.random(1,total_weight)
	for i,value in ipairs(value_weight_list) do
		if value[2] < random_weight then
			random_weight = random_weight - value[2]
		else
			return value[1]
		end
	end
	return nil
end

function RandomManager:get_random_list_in_weight(total_weight,value_weight_list,count)
	if total_weight == 0 or #value_weight_list == 0 then
		return nil
	end 
	local result = {}
	if #value_weight_list <= count then
		for i,v in ipairs(value_weight_list) do
			table.insert(result,v)
		end
		return result
	end
	for i=1,count do
		local random_weight = math.random(1,total_weight)
		for i,value in pairs(value_weight_list) do
			if value[2] < random_weight then
				random_weight = random_weight - value[2]
			else
				table.insert(result,value[1])
				total_weight = total_weight - value[2]
				value_weight_list[i] = nil
			end
		end
	end
	return result
end

function RandomManager:get_random_int(mix,max)
	return math.random(mix,max)
end

return RandomManager