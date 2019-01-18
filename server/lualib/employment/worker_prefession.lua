local class = require "class"
local WorkerPrefession = class()
local utils = require "utils"

function WorkerPrefession:ctor(prefession_config)
    self.__prefession_index = prefession_config.prefession_index

    self.__profession_skill = prefession_config.profession_skill
    self.__skill_weight = prefession_config.skill_weight
end

function WorkerPrefession:get_prefession_skills()
    return self.__profession_skill
end

function WorkerPrefession:get_skills_weight()
    return self.__skill_weight
end

return WorkerPrefession