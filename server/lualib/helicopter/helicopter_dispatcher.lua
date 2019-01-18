local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local HelicopterDispatcher = class()

function HelicopterDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function HelicopterDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function HelicopterDispatcher:init()
    self:register_c2s_callback("unlock_helicopter",self.dispatcher_unlock_helicopter)
    self:register_c2s_callback("request_helicopter",self.dispatcher_request_helicopter)
    self:register_c2s_callback("delete_helicopter_order",self.dispatcher_delete_helicopter_order)
    self:register_c2s_callback("finish_helicopter_order",self.dispatcher_finish_helicopter_order)
    self:register_c2s_callback("promote_helicopter_order",self.dispatcher_promote_helicopter_order)
end

function HelicopterDispatcher.dispatcher_unlock_helicopter(role_object,msg_data)
    local helicopter_ruler = role_object:get_helicopter_ruler()
    local result = helicopter_ruler:unlock_helicopter()
    local order_objects = helicopter_ruler:dump_order_objects()
    return {result = result, order_objects = order_objects}
end

function HelicopterDispatcher.dispatcher_request_helicopter(role_object,msg_data)
    local helicopter_ruler = role_object:get_helicopter_ruler()
    local result = helicopter_ruler:request_helicopter()
    local order_objects = helicopter_ruler:dump_order_objects()
    return {result = result, order_objects = order_objects}
end

function HelicopterDispatcher.dispatcher_delete_helicopter_order(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local order_index = msg_data.order_index
    local helicopter_ruler = role_object:get_helicopter_ruler()
    local result = helicopter_ruler:delete_helicopter_order(timestamp,order_index)
    local order_objects = helicopter_ruler:dump_order_objects()
    return {result = result, order_objects = order_objects}
end

function HelicopterDispatcher.dispatcher_finish_helicopter_order(role_object,msg_data)
    local order_index = msg_data.order_index
    local item_objects = msg_data.item_objects
    local gold_count = msg_data.gold_count
    local timestamp = msg_data.timestamp
    local helicopter_ruler = role_object:get_helicopter_ruler()
    local result = helicopter_ruler:finish_helicopter_order(order_index,item_objects,gold_count,timestamp)
    local order_objects = helicopter_ruler:dump_order_objects()
    return {result = result, order_objects = order_objects}
end

function HelicopterDispatcher.dispatcher_promote_helicopter_order(role_object,msg_data)
    local order_index = msg_data.order_index
    local timestamp = msg_data.timestamp
    local cash_count = msg_data.cash_count
    local helicopter_ruler = role_object:get_helicopter_ruler()
    local result = helicopter_ruler:promote_helicopter_order(timestamp,order_index,cash_count)
    return {result = result}
end

return HelicopterDispatcher