local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local DailyDispatcher = class()
local UNLOCKLEVEL = 3

function DailyDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function DailyDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function DailyDispatcher:register_s2c_callback(request_name,callback)
    self.__role_object:register_s2c_callback(request_name,callback)
end

function DailyDispatcher:init()
    self:register_c2s_callback("request_daily",self.dispatcher_request_daily)
    self:register_c2s_callback("receive_daily",self.dispatcher_receive_daily)
    self:register_c2s_callback("finish_task",self.dispatcher_finish_task)
    self:register_c2s_callback("finish_seven_task",self.dispatcher_finish_seven_task)

    self:register_s2c_callback("task_finish",self.dispatcher_task_finish)
    self:register_s2c_callback("seven_finish",self.dispatcher_seven_finish)
    self:register_s2c_callback("unlock_seven",self.dispatcher_unlock_seven)
end

function DailyDispatcher.dispatcher_unlock_seven(role_object,args,msg_data)
end

function DailyDispatcher.dispatcher_seven_finish(role_object,args,msg_data)
end

function DailyDispatcher.dispatcher_task_finish(role_object,args,msg_data)
    
end

function DailyDispatcher.dispatcher_finish_seven_task(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local task_index = msg_data.task_index
    local daily_ruler = role_object:get_daily_ruler()
    local result = daily_ruler:finish_seven(task_index,timestamp)
    return {result = result}
end

function DailyDispatcher.dispatcher_finish_task(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local task_index = msg_data.task_index
    local daily_ruler = role_object:get_daily_ruler()
    daily_ruler:refresh_daily(timestamp)
    local result = daily_ruler:finish_task(task_index)
    return {result = result}
end

function DailyDispatcher.dispatcher_receive_daily(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local reward_index = msg_data.reward_index
    local daily_ruler = role_object:get_daily_ruler()
    daily_ruler:refresh_daily(timestamp)
    local result = daily_ruler:receive_daily(reward_index)
    return {result = result}
end

function DailyDispatcher.dispatcher_request_daily(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local daily_ruler = role_object:get_daily_ruler()
    daily_ruler:refresh_daily(timestamp)
    local task_objects = daily_ruler:dump_task_objects()
    local reward_objects = daily_ruler:dump_reward_objects()
    return {task_objects=task_objects,reward_objects=reward_objects}
end

return DailyDispatcher