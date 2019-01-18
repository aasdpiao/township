local class = require "class"

local RewardEntry = class()

function RewardEntry:ctor(reward_index,item_index,item_count,unlock_level,weight)
    self.__reward_index = reward_index
    self.__item_index = item_index
    self.__item_count = item_count
    self.__unlock_level = unlock_level
    self.__weight = weight
end

function RewardEntry:check_level(level)
    return self.__unlock_level <= level
end

function RewardEntry:get_weight()
    return self.__weight
end

function RewardEntry:get_reward_index()
    return self.__reward_index
end

function RewardEntry:get_item_index()
    return self.__item_index
end

function RewardEntry:get_item_count()
    return self.__item_count
end

return RewardEntry