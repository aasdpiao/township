local class = require "class"

local TaskEntry = class()

function TaskEntry:ctor(task_index)
    self.__task_index = task_index
    self.__unlock_level = 0
    self.__times = 0
    self.__gold = 0
    self.__exp = 0
    self.__weight = 10
end

function TaskEntry:load_task_entry(task_config)
    self.__unlock_level = task_config.unlock_level
    self.__times = task_config.times
    self.__gold = task_config.gold
    self.__exp = task_config.exp
end

function TaskEntry:get_random_weight()
    return self.__weight
end

function TaskEntry:check_unlock_level(level)
    return self.__unlock_level <= level
end

function TaskEntry:get_task_times()
    return self.__times
end

function TaskEntry:get_gold()
    return self.__gold
end

function TaskEntry:get_exp()
    return self.__exp
end

function TaskEntry:get_task_index()
    return self.__task_index
end

return TaskEntry