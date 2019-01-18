local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local EventDispatcher = class()

function EventDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function EventDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function EventDispatcher:init()
    self:register_c2s_callback("request_event",self.dispatcher_request_event)
    self:register_c2s_callback("finish_event",self.dispatcher_finish_event)
    self:register_c2s_callback("cancel_event",self.dispatcher_cancel_event)
end

function EventDispatcher.dispatcher_request_event(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local event_ruler = role_object:get_event_ruler()
    local result = event_ruler:request_event(timestamp)
    local timestamp = event_ruler:get_next_refresh_timestamp()
    local event_objects = event_ruler:dump_event_objects()
    return {result = result,timestamp=timestamp,event_objects=event_objects}
end

function EventDispatcher.dispatcher_finish_event(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local event_id = msg_data.event_id
    local event_ruler = role_object:get_event_ruler()
    local result = event_ruler:finish_event(timestamp,event_id)
    local timestamp = event_ruler:get_next_refresh_timestamp()
    return {result = result,timestamp=timestamp}
end

function EventDispatcher.dispatcher_cancel_event(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local event_id = msg_data.event_id
    local event_ruler = role_object:get_event_ruler()
    local result = event_ruler:cancel_event(timestamp,event_id)
    local timestamp = event_ruler:get_next_refresh_timestamp()
    return {result = result,timestamp=timestamp}
end

return EventDispatcher