local class = require "class"

local RewardObject = class()

function RewardObject:ctor(role_object)
    self.__role_object = role_object
    self.__reward_entry = nil
    self.__reward_index = 0
    self.__status = 0
end

function RewardObject:load_reward_object(reward_object)
    self.__reward_index = reward_object.reward_index
    self.__status = reward_object.status
    self.__reward_entry = self.__role_object:get_daily_ruler():get_daily_manager():get_reward_entry(self.__reward_index)
end

function RewardObject:dump_reward_object()
    local reward_object = {}
    reward_object.reward_index = self.__reward_index
    reward_object.status = self.__status
    return reward_object
end

function RewardObject:set_reward_index(reward_index)
    self.__reward_index = reward_index
    self.__reward_entry = self.__role_object:get_daily_ruler():get_daily_manager():get_reward_entry(self.__reward_index)
end

function RewardObject:check_can_receive()
    return self.__status <= 0
end

function RewardObject:receive_reward()
    local item_index = self.__reward_entry:get_item_index()
    local item_count = self.__reward_entry:get_item_count()
    self.__role_object:add_item(item_index,item_count,SOURCE_CODE.daily)
    self.__status = 1
end

return RewardObject