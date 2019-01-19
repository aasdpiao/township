local class = require "class"

local RewardObject = class()

function RewardObject:ctor(role_object,item_objects)
    self.__role_object = role_object
    self.__item_objects = item_objects
    self.__status = 0
end

function RewardObject:dump_reward_object()
    local reward_object = {}
    reward_object.status = self.__status
    reward_object.item_objects = self.__item_objects
    return reward_object
end

function RewardObject:set_status(status)
    self.__status = status
end

function RewardObject:check_can_receive()
    return self.__status == 0 
end

function RewardObject:receive_reward()
    for i,v in ipairs(self.__item_objects) do
        local item_index = v.item_index
        local item_count = v.item_count
        self.__role_object:add_item(item_index,item_count,SOURCE_CODE.reward)
        if item_index == 7001 then
            self.__role_object:get_achievement_ruler():flight_money(item_count)
        end
    end
    self.__status = 1
end

return RewardObject