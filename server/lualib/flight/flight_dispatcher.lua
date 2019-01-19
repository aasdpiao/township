local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local FlightDispatcher = class()

function FlightDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function FlightDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function FlightDispatcher:init()
    self:register_c2s_callback("unlock_flight",self.dispatcher_unlock_flight)
    self:register_c2s_callback("promote_flight",self.dispatcher_promote_flight)
    self:register_c2s_callback("finish_flight",self.dispatcher_finish_flight)
    self:register_c2s_callback("request_flight",self.dispatcher_request_flight)
    self:register_c2s_callback("finish_flight_order",self.dispatcher_finish_flight_order)
    self:register_c2s_callback("promote_back",self.dispatcher_promote_back)
    self:register_c2s_callback("take_off",self.dispatcher_take_off)
    self:register_c2s_callback("request_flight_help",self.dispatcher_request_flight_help)
    self:register_c2s_callback("finish_flight_help",self.dispatcher_finish_flight_help)
    self:register_c2s_callback("confirm_flight_help",self.dispatcher_confirm_flight_help)
end

function FlightDispatcher.dispatcher_request_flight_help(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local row = msg_data.row        --行
    local column = msg_data.column  --列
    local flight_ruler = role_object:get_flight_ruler()
    local result = flight_ruler:request_flight_help(timestamp,row,column)
    return {result = result}
end

function FlightDispatcher.dispatcher_finish_flight_help(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local row = msg_data.row        --行
    local column = msg_data.column  --列
    local account_id = msg_data.account_id
    local item_object = msg_data.item_object
    local item_index = item_object.item_index
    local item_count = item_object.item_count
    local flight_ruler = role_object:get_flight_ruler()
    if not role_object:check_enough_item(item_index,item_count) then
        LOG_ERROR("item_index:%d item_count:%d err:%s",item_index,item_count,errmsg(GAME_ERROR.item_not_enough))
        return GAME_ERROR.item_not_enough
    end
    local result,gold,exp,friendly = role_object:get_cache_ruler():finish_flight_help(account_id,timestamp,row,column)
    if result == 0 then
        role_object:consume_item(item_index,item_count,CONSUME_CODE.help)
        role_object:add_gold(gold,SOURCE_CODE.help)
        role_object:add_exp(exp,SOURCE_CODE.help)
        role_object:add_friendly(friendly,SOURCE_CODE.help)
        role_object:get_daily_ruler():help_flight()
        result = flight_ruler:order_help(item_object,gold,exp)
    end
    return {result = result}
end

function FlightDispatcher.dispatcher_confirm_flight_help(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local row = msg_data.row        --行
    local column = msg_data.column  --列
    local flight_ruler = role_object:get_flight_ruler()
    local result = flight_ruler:confirm_flight_help(timestamp,row,column)
    return {result = result}
end

function FlightDispatcher.dispatcher_take_off(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local flight_ruler = role_object:get_flight_ruler()
    if not flight_ruler:check_can_take_off(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_take_off))
        return GAME_ERROR.cant_take_off
    end
    local result = flight_ruler:flight_take_off(timestamp)
    local station_status = flight_ruler:get_station_status()
    local timestamp = flight_ruler:get_timestamp()
    return {result = result,station_status=station_status,timestamp=timestamp}
end

function FlightDispatcher.dispatcher_unlock_flight(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local gold_count = msg_data.gold_count
    local flight_ruler = role_object:get_flight_ruler()
    if not flight_ruler:check_can_unlock() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_unlock))
        return {result = GAME_ERROR.cant_unlock} 
    end
    local result = flight_ruler:unlock_station(timestamp,gold_count)
    return {result = result}
end

function FlightDispatcher.dispatcher_promote_flight(role_object,msg_data)
    local cash_count = msg_data.cash_count
    local timestamp = msg_data.timestamp
    local flight_ruler = role_object:get_flight_ruler()
    local result = flight_ruler:promote_flight(cash_count,timestamp)
    return {result = result}
end

function FlightDispatcher.dispatcher_finish_flight(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local item_objects = msg_data.item_objects or {}
    local flight_ruler = role_object:get_flight_ruler()
    local result = flight_ruler:finish_flight(timestamp,item_objects)
    local flight_orders = flight_ruler:dump_order_objects()
    local flight_rewards = flight_ruler:dump_order_rewards()
    local station_status = flight_ruler:get_station_status()
    local timestamp = flight_ruler:get_timestamp()
    return {result = result,flight_orders = flight_orders,flight_rewards=flight_rewards,station_status= station_status,timestamp=timestamp}
end

function FlightDispatcher.dispatcher_request_flight(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local flight_ruler = role_object:get_flight_ruler()
    local result = flight_ruler:request_flight(timestamp)
    local flight_orders = flight_ruler:dump_order_objects()
    local flight_rewards = flight_ruler:dump_order_rewards()
    local station_status = flight_ruler:get_station_status()
    local timestamp = flight_ruler:get_timestamp()
    return {result = result,flight_orders = flight_orders,flight_rewards=flight_rewards,station_status= station_status,timestamp=timestamp}
end

function FlightDispatcher.dispatcher_finish_flight_order(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local row = msg_data.row        --行
    local column = msg_data.column  --列
    local item_object = msg_data.item_object
    local flight_ruler = role_object:get_flight_ruler()
    local result = flight_ruler:finish_flight_order(timestamp,row,column,item_object)
    return {result = result}
end

function FlightDispatcher.dispatcher_promote_back(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local cash_count = msg_data.cash_count
    local flight_ruler = role_object:get_flight_ruler()
    local result = flight_ruler:promote_back(timestamp,cash_count)
    local flight_orders = flight_ruler:dump_order_objects()
    local flight_rewards = flight_ruler:dump_order_rewards()
    local station_status = flight_ruler:get_station_status()
    local timestamp = flight_ruler:get_timestamp()
    return {result = result,flight_orders = flight_orders,flight_rewards=flight_rewards,station_status= station_status,timestamp=timestamp}
end

return FlightDispatcher