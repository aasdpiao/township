local class = require "class"
local WorkerProfession = class()
local utils = require "utils"

function WorkerProfession:ctor(profession_config)
    self.__profession_index = profession_config.profession_index

    self.__profession_skill = profession_config.profession_skill
    self.__skill_weight = profession_config.skill_weight
end

function WorkerProfession:get_profession_skills()
    return self.__profession_skill
end

function WorkerProfession:get_skills_weight()
    return self.__skill_weight
end

return WorkerProfession