local class = require "class"

local TaskObject = class()

function TaskObject:ctor(role_object)
    self.__role_object = role_object
    self.__task_entry = nil
    self.__task_index = 0
    self.__times = 0
    self.__status = 0
end

function TaskObject:get_task_index()
    return self.__task_index
end

function TaskObject:set_task_index(task_index)
    self.__task_index = task_index
    self.__task_entry = self.__role_object:get_daily_ruler():get_daily_manager():get_task_entry(task_index)
end

function TaskObject:load_task_object(task_object)
    self.__task_index = task_object.task_index
    self.__times = task_object.times
    self.__status = task_object.status
    self.__task_entry = self.__role_object:get_daily_ruler():get_daily_manager():get_task_entry(self.__task_index)
end

function TaskObject:dump_task_object()
    local task_object = {}
    task_object.task_index = self.__task_index
    task_object.times = self.__times
    task_object.status = self.__status
    return task_object
end

function TaskObject:check_can_finish()
    if self.__status >= 1 then return false end
    local times = self.__task_entry:get_task_times()
    return self.__times >= times
end

function TaskObject:check_finish()
    return self.__status >= 1
end

function TaskObject:finish_task()
    self.__status = 1
    local gold = self.__task_entry:get_gold()
    local exp = self.__task_entry:get_exp()
    self.__role_object:add_gold(gold,SOURCE_CODE.task)
    self.__role_object:add_exp(exp,SOURCE_CODE.task)
end

function TaskObject:add_times(count)
    self.__times = self.__times + count
end

function TaskObject:get_times()
    return self.__times
end

return TaskObject