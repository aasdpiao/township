local class = require "class"

local RewardObject = class()

local reward_status = {}
reward_status.unaccalimed = 1
reward_status.received = 2

function RewardObject:ctor(reward_entry)
    self.__reward_entry = reward_entry
    self.__item_index = reward_entry:get_item_index()
    self.__item_count = reward_entry:get_item_count()
    self.__status = reward_status.unaccalimed
end

function RewardObject:get_status()
    return self.__status
end

function RewardObject:dump_reward_object()
    local reward_object = {}
    reward_object.reward_index = self.__reward_entry:get_reward_index()
    reward_object.item_index = self.__item_index
    reward_object.item_count = self.__item_count
    reward_object.status = self.__status
    return reward_object
end

function RewardObject:get_item_index()
    return self.__item_index
end

function RewardObject:get_item_count()
    return self.__item_count
end

function RewardObject:load_reward_object(reward_object)
    self.__status = reward_object.status 
end

function RewardObject:finish_reward_object()
    self.__status = reward_status.received
end

function RewardObject:check_can_reward()
    return self.__status == reward_status.unaccalimed
end

function RewardObject:is_get_reward()
    return self.__status == reward_status.received
end

function RewardObject:debug_info()
    local reward_info = ""
    reward_info = reward_info.."item_index:"..self.__item_index.."\n"
    reward_info = reward_info.."item_count:"..self.__item_count.."\n"
    reward_info = reward_info.."status:"..self.__status.."\n"
    return reward_info
end

return RewardObject