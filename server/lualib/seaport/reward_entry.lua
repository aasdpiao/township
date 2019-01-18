local class = require "class"
local utils = require "utils"

local RewardEntry = class()

function RewardEntry:ctor(reward_config)
    self.__reward_index = reward_config.index
    self.__item_index = reward_config.item_index
    self.__reward_type = reward_config.reward_type
    self.__unlock_level = reward_config.unlock_level
    self.__produce_exp = reward_config.produce_exp
    self.__weight = reward_config.weight
    self.__count_entrys = {}
    self.__total_weight = 0
    local item_count = reward_config.item_count
    local count_weight = reward_config.count_weight
    for i,v in ipairs(item_count) do
        local weight = count_weight[i]
        self.__total_weight = self.__total_weight + weight
        self.__count_entrys[i] = {v,weight}
    end
end

function RewardEntry:check_level(level)
    return self.__unlock_level <= level
end

function RewardEntry:get_reward_index()
    return self.__reward_index
end

function RewardEntry:get_item_index()
    return self.__item_index
end

function RewardEntry:generate_item_count()
    return utils.get_random_value_in_weight(self.__total_weight,self.__count_entrys)
end

function RewardEntry:get_weight()
    return self.__weight
end

function RewardEntry:get_exp_count()
    return self.__produce_exp
end

return RewardEntry