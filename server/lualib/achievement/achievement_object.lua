local class = require "class"
local RecordObject = require "achievement.record_object"

local AchievementObject = class()

function AchievementObject:ctor(role_object,achievement_entry)
    self.__role_object = role_object
    self.__achievement_entry = achievement_entry
    self.__achievement_type = achievement_entry:get_achievement_type()
    self.__status = 1
    self.__finish_times = 0
    self.__achievement_records = {}
    self.__receive = 1
end

function AchievementObject:dump_achievement_object()
    local achievement_object = {}
    achievement_object.achievement_type = self.__achievement_type
    achievement_object.status = self.__status
    achievement_object.finish_times = self.__finish_times
    achievement_object.receive = self.__receive
    achievement_object.achievement_records = self:dump_achievement_records()
    return achievement_object
end

function AchievementObject:dump_achievement_records()
    local achievement_records = {}
    for i,v in ipairs(self.__achievement_records) do
        achievement_records[i] = v:dump_achievement_record()
    end
    return achievement_records
end

function AchievementObject:load_achievement_object(achievement_object)
    self.__status = achievement_object.status or 1
    self.__finish_times = achievement_object.finish_times or 0
    self.__receive = achievement_object.receive or 1
    local achievement_records = achievement_object.achievement_records or {}
    self:load_achievement_records(achievement_records)
end

function AchievementObject:load_achievement_records(achievement_records)
    self.__achievement_records = {}
    for i,v in ipairs(achievement_records) do
        local timestamp = v.timestamp
        local finish_times = v.finish_times
        local achievement_record = RecordObject.new(self.__role_object,timestamp,finish_times,self.__achievement_entry)
        self.__achievement_records[i] = achievement_record
    end
end

function AchievementObject:add_finish_times(times)
    times = times or 1
    if self.__status > 4 then return end
    local achievement_stage = self.__achievement_entry:get_achievement_stage(self.__status)
    self.__finish_times = self.__finish_times + times
    local finish_times = achievement_stage:get_total_times()
    if self.__finish_times >= finish_times then
        self.__role_object:get_achievement_ruler():finish_achievement_object(self.__achievement_type,self.__status)
        self.__status = self.__status + 1 
    end
end

function AchievementObject:refresh_finish_times(times)
    if self.__status > 4 then return end
    local achievement_stage = self.__achievement_entry:get_achievement_stage(self.__status)
    self.__finish_times = times
    local finish_times = achievement_stage:get_total_times()
    if self.__finish_times >= finish_times then
        self.__role_object:get_achievement_ruler():finish_achievement_object(self.__achievement_type,self.__status)
        self.__status = self.__status + 1 
    end
end

function AchievementObject:refresh_record_object(timestamp)
    if self.__status > 4 then return end
    local achievement_stage = self.__achievement_entry:get_achievement_stage(self.__status)
    local limit_time = achievement_stage:get_limit_time()
    local limit_timestamp = timestamp - limit_time
    local achievement_records = {}
    for i,v in ipairs(self.__achievement_records) do
        if v:check_limit_timestamp(limit_timestamp) then
            table.insert( achievement_records, v )
        end
    end
    self.__achievement_records = achievement_records
end

function AchievementObject:add_record_object(timestamp,count)
    local record_object = RecordObject.new(self.__role_object,timestamp,count,self.__achievement_entry)
    table.insert(self.__achievement_records,record_object)
    local achievement_stage = self.__achievement_entry:get_achievement_stage(self.__status)
    local times = achievement_stage:get_total_times()
    local total_count = 0
    for i,v in ipairs(self.__achievement_records) do
        total_count = total_count + v:get_finish_times()
    end
    if total_count > self.__finish_times then
        self.__finish_times = total_count
    end
    if total_count >= times then
        self.__role_object:get_achievement_ruler():finish_achievement_object(self.__achievement_type,self.__status)
        self.__status = self.__status + 1 
    end
end

function AchievementObject:check_can_receive(stage)
    if self.__receive ~= stage then return false end
    return self.__receive < self.__status
end

function AchievementObject:receive_achievement(status)
    self.__receive = status+1
end

return AchievementObject