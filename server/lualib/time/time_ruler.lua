local class = require "class"
local skynet = require "skynet"
local TimeDispatcher = require "time.time_dispatcher"

local TimeRuler = class()

function TimeRuler:ctor(role_object)
    self.__role_object = role_object
end

function TimeRuler:init()
    self.__time_dispatcher = TimeDispatcher.new(self.__role_object)
    self.__time_dispatcher:init()
end

function TimeRuler:get_current_time()
    local timestamp = skynet.call("timed","lua","query_current_time")
    return timestamp
end

function TimeRuler:check_time(timestamp)
    local current_time = self:get_current_time()
    return current_time >= timestamp
end

function TimeRuler:set_current_time(timestamp)
    skynet.call("timed","lua","set_current_time",timestamp)
end

return TimeRuler