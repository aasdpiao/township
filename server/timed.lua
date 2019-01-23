local skynet = require "skynet"
require "skynet.manager"
local multicast = require "skynet.multicast"
local datacenter = require "skynet.datacenter"

local CMD = {}

local time_default = 0
local timesync_mc

function CMD.query_current_time()
    return os.time() + time_default
end

function CMD.set_current_time(timestamp)
    time_default = timestamp - os.time() 
    timesync_mc:publish(timestamp)
end

skynet.start(function()
    skynet.dispatch("lua", function (_,_,cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        end
    end)
    timesync_mc = multicast.new()
    datacenter.set("TIMESYNC",timesync_mc.channel)
	skynet.register(SERVICE_NAME)
end)