local class = require "class"

local AchievementStage = class()

function AchievementStage:ctor(achievement_config)
    self.__achievement_index = achievement_config.index
    self.__achievement_type = achievement_config.type
    self.__total = achievement_config.total
    self.__cash = achievement_config.cash
    self.__exp = achievement_config.exp
    self.__limit_time = achievement_config.limit_time
end

function AchievementStage:get_achievement_index()
    return self.__achievement_index
end

function AchievementStage:get_achievement_type()
    return self.__achievement_type
end

function AchievementStage:get_limit_time()
    return self.__limit_time
end

function AchievementStage:get_total_times()
    return self.__total
end

function AchievementStage:get_exp()
    return self.__exp
end

function AchievementStage:get_cash()
    return self.__cash
end

return AchievementStage