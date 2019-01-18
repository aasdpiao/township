local class = require "class"
local WorkerSkill = class()

function WorkerSkill:ctor(skill_config)
    self.__skill_index = skill_config.skill_index
    self.__unlock_level = skill_config.unlock_level
    self.__skill_type = skill_config.skill_type
    self.__skill_item = skill_config.skill_Item
    self.__skill_formula = skill_config.skill_pink
end

function WorkerSkill:get_skill_index()
    return self.__skill_index
end

function WorkerSkill:check_unlock(level)
    return self.__unlock_level <= level
end

function WorkerSkill:get_skill_item()
    return self.__skill_item
end

function WorkerSkill:get_skill_formula()
    return self.__skill_formula
end

return WorkerSkill