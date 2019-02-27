local class = require "class"

local SevenEntry = class()

function SevenEntry:ctor()
end

function SevenEntry:load_seven_entry(seven_entry)
    self.__task_index = seven_entry.index
    self.__day_times = seven_entry.daytimes
    self.__task_type = seven_entry.type
    self.__total = seven_entry.total
    self.__exp = seven_entry.exp
    self.__rewards = {}
    local items = seven_entry.items
    local items_count = seven_entry.items_count
    for i,v in ipairs(items) do
        self.__rewards[v] = items_count[i]
    end
end

function SevenEntry:get_task_times()
    return self.__total
end

return SevenEntry