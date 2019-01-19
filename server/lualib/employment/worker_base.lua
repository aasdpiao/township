local class = require "class"

local WorkerBase = class()

function WorkerBase:ctor()
end

function WorkerBase:get_worker_id()
    return self.__worker_id
end

function WorkerBase:set_worker_index(worker_index)
    self.__worker_index = worker_index
end

function WorkerBase:get_worker_index()
    return self.__worker_index
end

function WorkerBase:set_worker_level(level)
    self.__level = level
end

function WorkerBase:get_worker_level()
    return self.__level
end

function WorkerBase:set_worker_state(state)
    self.__state = state
end

function WorkerBase:get_worker_state()
    return self.__state
end

function WorkerBase:set_worker_exp(exp)
    self.__exp = exp
end

function WorkerBase:get_worker_exp()
    return self.__exp
end

function WorkerBase:set_worker_profession(profession)
    self.__profession = profession
end

function WorkerBase:get_worker_profession()
    return self.__profession
end

function WorkerBase:set_worker_skills(skills)
    self.__skills = skills
end

function WorkerBase:get_worker_skills()
    return self.__skills
end

function WorkerBase:add_worker_exp(exp)
    local employment_manager = self.__role_object:get_employment_ruler():get_employment_manager()
    local levelup_entry = employment_manager:get_levelup_entry(self.__level)
    local max_exp = levelup_entry:get_max_exp()
    self.__exp = self.__exp + exp
    if self.__exp < max_exp then return end
    if not self:check_can_levelup() then return end
    self.__level = self.__level + 1
    exp = self.__exp - max_exp
    self.__exp = 0
    self:add_worker_exp(exp)
end

function WorkerBase:check_can_levelup()
    local max_level = self.__state * 5
    return self.__level < max_level
end

function WorkerBase:check_can_upgrade()
    if self.__state >= 5 then return false end
    local max_level = self.__state * 5
    return self.__level == max_level
end

function WorkerBase:upgrade_worker()
    self.__state = self.__state + 1
    self:add_worker_exp(0)
    if self.__state == 5 then
        self.__role_object:get_achievement_ruler():levelup_worker(1)
    end
end

return WorkerBase