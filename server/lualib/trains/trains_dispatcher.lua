local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local TrainDispatcher = class()

function TrainDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function TrainDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function TrainDispatcher:init()
    self:register_c2s_callback("unlock_trains",self.dispatcher_unlock_trains)
    self:register_c2s_callback("finish_trains_order",self.dispatcher_finish_trains_order)
    self:register_c2s_callback("promote_trains",self.dispatcher_promote_trains)
    self:register_c2s_callback("get_trains_reward",self.dispatcher_get_trains_reward)
    self:register_c2s_callback("request_order_help",self.dispatcher_request_order_help)
    self:register_c2s_callback("finish_order_help",self.dispatcher_finish_order_help)
    self:register_c2s_callback("request_new_trains",self.dispatcher_request_new_trains)
    self:register_c2s_callback("unlock_trains_station",self.dispatcher_unlock_trains_station)
    self:register_c2s_callback("confirm_friends_help",self.dispatcher_confirm_friends_help)
end

function TrainDispatcher.dispatcher_confirm_friends_help(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local trains_index = msg_data.trains_index
    local order_index = msg_data.order_index
    local trains_ruler = role_object:get_trains_ruler()
    local result = trains_ruler:confirm_friends_help(trains_index,timestamp,order_index)
    return {result = result}
end

function TrainDispatcher.dispatcher_unlock_trains(role_object,msg_data)
    local trains_index = msg_data.trains_index
    local result = role_object:get_trains_ruler():unlock_trains(trains_index)
    local trains_object = role_object:get_trains_ruler():get_trains_object(trains_index)
    return {result = result,trains_object = trains_object:dump_trains_object()}
end

function TrainDispatcher.dispatcher_finish_trains_order(role_object,msg_data)
    local order_objects = msg_data.order_objects
    local trains_index = msg_data.trains_index
    local timestamp = msg_data.timestamp
    local trains_object = role_object:get_trains_ruler():get_trains_object(trains_index)
    if not trains_object then
        LOG_ERROR("trains_index:%d err:%s",trains_index,errmsg(GAME_ERROR.trains_not_exist))
        return {result = GAME_ERROR.trains_not_exist}
    end
    for i,order_object in ipairs(order_objects) do
        local result = trains_object:finish_trains_order(order_object)
        if result > 0 then return {reuslt = result} end
    end
    trains_object:flush_trains_status(timestamp)
    return {result = 0}
end

function TrainDispatcher.dispatcher_promote_trains(role_object,msg_data)
    local trains_index = msg_data.trains_index
    local timestamp = msg_data.timestamp
    local cash_count = msg_data.cash_count
    local trains_object = role_object:get_trains_ruler():get_trains_object(trains_index)
    if not trains_object then
        LOG_ERROR("trains_index:%d err:%s",trains_index,errmsg(GAME_ERROR.trains_not_exist))
        return {result = GAME_ERROR.trains_not_exist} 
    end
    trains_object:flush_trains_status(timestamp)
    local result = trains_object:promote_trains(timestamp,cash_count)
    return {result = result}
end

function TrainDispatcher.dispatcher_get_trains_reward(role_object,msg_data)
    local trains_index = msg_data.trains_index
    local timestamp = msg_data.timestamp
    local reward_objects = msg_data.reward_objects
    local trains_object = role_object:get_trains_ruler():get_trains_object(trains_index)
    if not trains_object then
        LOG_ERROR("trains_index:%d err:%s",trains_index,errmsg(GAME_ERROR.trains_not_exist))
        return {result = GAME_ERROR.trains_not_exist} 
    end
    trains_object:flush_trains_status(timestamp)
    for i,reward_object in ipairs(reward_objects) do
        local result = trains_object:get_trains_reward(reward_object)
        if result > 0 then return {reuslt = result} end
    end
    return {result = 0}
end

function TrainDispatcher.dispatcher_request_order_help(role_object,msg_data)
    local trains_index = msg_data.trains_index
    local order_object = msg_data.order_object
    local trains_object = role_object:get_trains_ruler():get_trains_object(trains_index)
    if not trains_object then 
        LOG_ERROR("trains_index:%d err:%s",trains_index,errmsg(GAME_ERROR.trains_not_exist))
        return {result = GAME_ERROR.trains_not_exist}
    end
    local result = trains_object:request_order_help(order_object)
    return {result = result}
end

function TrainDispatcher.dispatcher_finish_order_help(role_object,msg_data)
    local account_id = msg_data.account_id
    local trains_index = msg_data.trains_index
    local order_object = msg_data.order_object
    local order_index = order_object.order_index
    local item_index = order_object.item_index
    local item_count = order_object.item_count
    if not role_object:check_enough_item(item_index,item_count) then
        LOG_ERROR("item_index:%d item_count:%d err:%s",item_index,item_count,errmsg(GAME_ERROR.item_not_enough))
        return {result = GAME_ERROR.item_not_enough}
    end
    local result,exp,friendly = role_object:get_cache_ruler():finish_trains_help(account_id,trains_index,order_object)
    if result == 0 then
        role_object:consume_item(item_index,item_count,CONSUME_CODE.help)
        role_object:add_exp(exp,SOURCE_CODE.help)
        role_object:add_friendly(friendly,SOURCE_CODE.help)
        role_object:get_daily_ruler():help_trains()
        role_object:get_daily_ruler():seven_help_trains()
        role_object:get_event_ruler():main_task_help_trains()
    end
    return {result = result}
end

function TrainDispatcher.dispatcher_request_new_trains(role_object,msg_data)
    local trains_index = msg_data.trains_index
    local trains_object = role_object:get_trains_ruler():get_trains_object(trains_index)
    if not trains_object then
        LOG_ERROR("trains_index:%d err:%s",trains_index,errmsg(GAME_ERROR.trains_not_exist))
        return {result = GAME_ERROR.trains_not_exist}
    end
    local result = trains_object:request_new_trains(trains_index)
    return {result = result,trains_object = trains_object:dump_trains_object()}
end

function TrainDispatcher.dispatcher_unlock_trains_station(role_object,msg_data)
    local trains_ruler = role_object:get_trains_ruler()
    if not trains_ruler:check_can_unlock_station() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_unlock))
        return {result = GAME_ERROR.cant_unlock}
    end
    trains_ruler:unlock_station()
    return {result = 0}
end

return TrainDispatcher