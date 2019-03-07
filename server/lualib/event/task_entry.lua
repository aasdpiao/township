local class = require "class"

local TaskEntry = class()

function TaskEntry:ctor()
end

function TaskEntry:load_task_entry(task_config)
	self.__task_index = task_config.index
	self.__task_type = task_config.type
	self.__relate_index = task_config.relate_index
	self.__times = task_config.total
	self.__exp = task_config.exp
	self.__rewards = {}
	local items = task_config.items
	local items_count = task_config.items_count
	for i,v in ipairs(items) do
		self.__rewards[v] = items_count[i]
	end
end

function TaskEntry:get_task_index()
	return self.__task_index
end

function TaskEntry:get_task_type()
	return self.__task_type
end

function TaskEntry:get_relate_index()
	return self.__relate_index
end

function TaskEntry:get_task_times()
	return self.__times
end

function TaskEntry:get_exp()
	return self.__exp
end

function TaskEntry:get_rewards()
	return self.__rewards
end

return TaskEntry