local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.query_current_time()
    return os.time()
end

skynet.start(function()
    skynet.dispatch("lua", function (_,_,cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        end
    end)
	skynet.register(SERVICE_NAME)
end)