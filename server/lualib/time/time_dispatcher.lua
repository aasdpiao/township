local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local TimeDispatcher = class()

function TimeDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function TimeDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function TimeDispatcher:init()
    self:register_c2s_callback("synctime",self.dispatcher_synctime)
end

--同步时间
function TimeDispatcher.dispatcher_synctime(role_object,msg_data)
    local timed = skynet.queryservice("timed")
    local timestamp = skynet.call(timed,"lua","query_current_time")
    return {result = 0 ,timestamp = timestamp}
end

return TimeDispatcher

