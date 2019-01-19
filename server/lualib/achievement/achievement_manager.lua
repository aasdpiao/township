local class = require "class"
local AchievementEntry = require "achievement.achievement_entry"
local datacenter = require "skynet.datacenter"

local AchievementManager = class()

function AchievementManager:ctor(role_object)
    self.__role_object = role_object
    self.__achievement_entrys = {}
end

function AchievementManager:init()
    self:load_achievement_config()
end

function AchievementManager:load_achievement_config()
    local achievement_config = datacenter.get("achievement_config")
    for k,v in pairs(achievement_config) do
        local achievement_index = v.index
        local achievement_type = v.type
        if not self.__achievement_entrys[achievement_type] then 
            local achievement_entry = AchievementEntry.new(achievement_type)
            self.__achievement_entrys[achievement_type] = achievement_entry
        end
        local achievement_entry = self.__achievement_entrys[achievement_type]
        achievement_entry:add_achievement_config(v)
    end
end

function AchievementManager:get_achievement_entry(achievement_type)
    return self.__achievement_entrys[achievement_type]
end

return AchievementManager