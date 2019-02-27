local class = require "class"

local SevenTask = class()

function SevenTask:ctor(role_object,seven_entry)
    self.__role_object = role_object
    self.__seven_entry = seven_entry
    self.__task_index = seven_entry:get_task_index()
    self.__task_type = seven_entry:get_task_type()
    self.__times = 0
    self.__status = 0
end

function SevenTask:load_seven_task(seven_task)
    self.__times = seven_task.times
    self.__status = seven_task.status
end

function SevenTask:dump_seven_task()
    local seven_task = {}
    seven_task.task_index = self.__task_index
    seven_task.times = self.__times
    seven_task.status = self.__status
    return seven_task
end

function SevenTask:get_task_index()
    return self.__task_index
end

function SevenTask:get_times()
    return self.__times
end

function SevenTask:finish_seven_task(count)
    self.__times = self.__times + count
end

function SevenTask:check_can_finish()
    if self.__status == 1 then return false end
    local total = self.__seven_entry:get_task_times()
    return self.__times >= total
end

return SevenTask