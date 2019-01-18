local class = require "class"

local RoleEntry = class()

function RoleEntry:ctor(level_config)
    self.__level = level_config.level
    self.__exp = level_config.exp
    self.__unlock = level_config.unlock
    self.__unlock_build = level_config.unlock_build
    self.__add_build = level_config.add_build
    self.__reward_gold = level_config.reward_gold
    self.__reward_cash = level_config.reward_cash
    local reward_item = level_config.reward_item
    local reward_item_count = level_config.reward_item_count
    self.__reward_item = {}
    for k,v in ipairs(reward_item) do
        self.__reward_item[v] = reward_item_count[k]
    end
    self.__trains_exp = level_config.trains_exp
    self.__flight_exp = level_config.plane_exp
    self.__helicopter_exp = level_config.helicopter_exp
    self.__event_upper = level_config.event_upper

    self.__cars_weight = 0
    self.__unm_cars = {}
    local num_cars = level_config.num_cars
    local weight_cars = level_config.weight_cars
    for i,v in ipairs(num_cars) do
        table.insert(self.__unm_cars,{v,weight_cars[i]})
        self.__cars_weight = self.__cars_weight + weight_cars[i]
    end
    self.__helicopter_weight = 0
    self.__helicopter_boxes = {}
    local num_helicopter = level_config.num_helicopter
    local weight_helicopter = level_config.weight_helicopter
    for i,v in ipairs(num_helicopter) do
        local weight = weight_helicopter[i]
        table.insert(self.__helicopter_boxes,{v,weight})
        self.__helicopter_weight = self.__helicopter_weight + weight
    end
end

function RoleEntry:get_max_exp()
    return self.__exp
end

function RoleEntry:get_reward_gold()
    return self.__reward_gold
end

function RoleEntry:get_reward_cash()
    return self.__reward_cash
end

function RoleEntry:get_reward_item()
    return self.__reward_item
end

function RoleEntry:get_num_cars()
    return self.__unm_cars
end

function RoleEntry:get_cars_total_weight()
    return self.__cars_weight
end

function RoleEntry:get_trains_exp()
    return self.__trains_exp
end

function RoleEntry:get_flight_exp()
    return self.__flight_exp
end

function RoleEntry:get_helicopter_exp()
    return self.__helicopter_exp
end

function RoleEntry:get_helicopter_boxes()
    return self.__helicopter_boxes
end

function RoleEntry:get_helicopter_total_weight()
    return self.__helicopter_weight
end

function RoleEntry:get_event_upper()
    return self.__event_upper
end

return RoleEntry