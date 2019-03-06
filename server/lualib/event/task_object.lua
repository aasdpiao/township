local class = require "class"

local TaskObject = class()

function TaskObject:ctor(role_object,task_entry)
    self.__role_object = role_object
    self.__task_entry = task_entry
    self.__task_index = task_entry:get_task_index()
    self.__times = 0
    self.__status = 0
end

function TaskObject:get_task_index()
    return self.__task_index
end

function TaskObject:get_task_type()
    return self.__task_entry:get_task_type()
end

function TaskObject:get_relate_index()
    return self.__task_entry:get_relate_index()
end

function TaskObject:dump_task_object(task_object)
    local task_object = {}
    task_object.task_index = self.__task_index
    task_object.times = self.__times
    task_object.status = self.__status
    return task_object
end

function TaskObject:load_task_object(task_object)
    self.__times = task_object.times
    self.__status = task_object.status
end

function TaskObject:finish_task_times(times)
    self.__times = self.__times + times
end

function TaskObject:refresh_task_times(times)
    if self.__times > times then return end
    self.__times = times
end

function TaskObject:check_task_finish()
    if self.__status == 1 then return false end
    local times = self.__task_entry:get_task_times()
    return self.__times >= times
end

return TaskObject