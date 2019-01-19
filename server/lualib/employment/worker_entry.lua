local class = require "class"
local WorkerEntry = class()

function WorkerEntry:ctor(worker_config)
    self.__worker_index = worker_config.worker_index
    self.__profession = worker_config.worker_type
end

function WorkerEntry:get_worker_index()
    return self.__worker_index
end

function WorkerEntry:get_professions()
    return self.__profession
end

return WorkerEntry