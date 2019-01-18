local class = require "class"

local RewardEntry = class()

function RewardEntry:ctor(reward_index)
    self.__reward_index = reward_index
    self.__item_index = 0
    self.__item_count = 0
    self.__reward_type = 0
    self.__weight = 0
end

function RewardEntry:load_reward_entry(reward_config)
    self.__item_index = reward_config.item_index
    self.__item_count = reward_config.item_count
    self.__reward_type = reward_config.reward_type
    self.__weight = reward_config.weight
end

function RewardEntry:get_random_weight()
    return self.__weight
end

function RewardEntry:get_reward_type()
    return self.__reward_type
end

function RewardEntry:get_item_index()
    return self.__item_index
end

function RewardEntry:get_item_count()
    return self.__item_count
end

function function_name(  )
    -- body
end

return RewardEntry