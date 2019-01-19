local class = require "class"

local RewardObject = class()

function RewardObject:ctor(role_object,reward_entry)
    self.__role_object = role_object
    self.__reward_entry = reward_entry
    self.__reward_index = reward_entry:get_reward_index()
    self.__item_count = 0
    self.__status = 0
end

function RewardObject:init_reward_object()
    self.__item_count = self.__reward_entry:generate_item_count()
end

function RewardObject:get_reward_index()
    return self.__reward_index
end

function RewardObject:get_item_index()
    return self.__reward_entry:get_item_index()
end

function RewardObject:get_item_count()
    return self.__item_count
end

function RewardObject:set_status(status)
    self.__status = status
end

function RewardObject:get_status()
    return self.__status
end

function RewardObject:set_item_count(item_count)
    self.__item_count = item_count
    if self.__item_count == 0 then
        self.__status = 1
    end
end

function RewardObject:get_exp_count()
    return self.__item_count * self.__reward_entry:get_exp_count()
end

function RewardObject:dump_reward_object()
    local reward_object = {}
    reward_object.reward_index = self.__reward_index
    reward_object.item_count = self.__item_count
    reward_object.status = self.__status
    return reward_object
end

return RewardObject