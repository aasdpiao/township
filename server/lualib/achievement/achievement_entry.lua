local class = require "class"
local AchievementStage = require "achievement.achievement_stage"

local AchievementEntry = class()

function AchievementEntry:ctor(achievement_type)
    self.__achievement_type = achievement_type  
    self.__achievement_stages = {}
end

function AchievementEntry:add_achievement_config(achievement_config)
    local achievement_stage = AchievementStage.new(achievement_config)
    local achievement_index = achievement_stage:get_achievement_index() 
    local index = achievement_index % 1000
    self.__achievement_stages[index] = achievement_stage
end

function AchievementEntry:get_achievement_type()
    return self.__achievement_type
end

function AchievementEntry:get_achievement_stage(stage)
    return self.__achievement_stages[stage]
end

return AchievementEntry