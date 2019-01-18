local class = require "class"

local LevelupEntry = class()

function LevelupEntry:ctor(levelup_config)
    self.__level = levelup_config.worker_level
    self.__worker_exp = levelup_config.worker_exp
    self.__worker_max_exp = levelup_config.worker_max_exp
    self.__accelerate   = levelup_config.reduce_time
end

function LevelupEntry:get_worker_exp()
    return self.__worker_exp
end

function LevelupEntry:get_max_exp()
    return self.__worker_max_exp
end

function LevelupEntry:get_accelerate()
    return self.__accelerate
end

return LevelupEntry
