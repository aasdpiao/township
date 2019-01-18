local class = require("class")

local TimeManager = class()

function TimeManager:ctor()
    self.__time_different = 0
end

function TimeManager:init()
end

function TimeManager:get_current_time()
    return os.time() - self.__time_different
end

function TimeManager:sync_time(time)
    self.__time_different = os.time() - time
    print("服务器时间校准:"..self.__time_different)
end

return TimeManager