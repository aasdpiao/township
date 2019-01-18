local class = require "class"

local RewardEntry = class()

function RewardEntry:ctor(reward_config)
    self.__reward_index = reward_config.reward_index
    self.__reward_item = reward_config.reward_item
    self.__reward_count = reward_config.reward_count
    self.__reward_weight = reward_config.reward_weight
    self.__unlock_level = reward_config.unlock_level
end

function RewardEntry:get_reward_index()
    return self.__reward_index
end

function RewardEntry:get_item_index()
    return self.__reward_item
end

function RewardEntry:get_item_count()
    return self.__reward_count
end

function RewardEntry:get_reward_weight()
    return self.__reward_weight
end

function RewardEntry:get_unlock_level()
    return self.__unlock_level
end

function RewardEntry:check_reward_available(role_object)
    return role_object:check_level(self.__unlock_level)
end

return RewardEntry