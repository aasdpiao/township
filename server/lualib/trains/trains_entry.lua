local class = require "class"

local TrainsEntry = class()

function TrainsEntry:ctor(trains_config)
    self.__trains_index = trains_config.trains_index
    local condition_counts = trains_config.condition_counts
    self.__unlock_level = condition_counts[1]
    self.__unlock_money = condition_counts[2]
end

function TrainsEntry:get_trains_index()
    return self.__trains_index
end

function TrainsEntry:get_unlock_level()
    return self.__unlock_level
end

function TrainsEntry:get_unlock_money()
    return self.__unlock_money
end

return TrainsEntry