local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local AchievementDispatcher = class()

function AchievementDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function AchievementDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function AchievementDispatcher:register_s2c_callback(request_name,callback)
    self.__role_object:register_s2c_callback(request_name,callback)
end

function AchievementDispatcher:init()
    self:register_c2s_callback("request_achievement",self.dispatcher_request_achievement)
    self:register_c2s_callback("receive_achievement",self.dispatcher_receive_achievement)

    self:register_s2c_callback("finish_achievement",self.dispatcher_finish_achievement)
end

function AchievementDispatcher.dispatcher_finish_achievement(role_object,args,msg_data)
    local result = msg_data.result
    LOG_INFO("finish_achieve",errmsg(result))
end

function AchievementDispatcher.dispatcher_request_achievement(role_object,msg_data)
    local achievement_ruler = role_object:get_achievement_ruler()
    local achievement_objects = achievement_ruler:dump_achievement_objects()
    local finish_helicopter = achievement_ruler:get_finish_helicopter()
    local finish_trains = achievement_ruler:get_finish_trains()
    local finish_flight = achievement_ruler:get_finish_flight()
    local finish_ship = achievement_ruler:get_finish_ship()
    local finish_product = achievement_ruler:get_finish_product()
    return {result = 0,achievement_objects = achievement_objects,finish_helicopter = finish_helicopter,
            finish_trains = finish_trains,finish_flight=finish_flight,finish_ship=finish_ship,finish_product=finish_product
    }
end

function AchievementDispatcher.dispatcher_receive_achievement(role_object,msg_data)
    local achievement_type = msg_data.achievement_type
    local status = msg_data.status
    local achievement_ruler = role_object:get_achievement_ruler()
    if not achievement_ruler:check_can_receive(achievement_type,status) then
        LOG_ERROR("achievement_type:%d status:%s error:%s",achievement_type,status,errmsg(GAME_ERROR.cant_receive_achievement))
        return GAME_ERROR.cant_receive_achievement     
    end
    local result,cash,exp = achievement_ruler:receive_achievement(achievement_type,status)
    return {result = result,cash=cash,exp=exp}
end

return AchievementDispatcher