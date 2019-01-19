local class = require "class"

local RecordObject = class()

function RecordObject:ctor(role_object,timestamp,finish_times,achievement_entry)
    self.__achievement_entry = achievement_entry
    self.__role_object = role_object
    self.__timestamp = timestamp
    self.__finish_times = finish_times
end

function RecordObject:dump_achievement_record()
    local achievement_record = {}
    achievement_record.timestamp = self.__timestamp
    achievement_record.finish_times = self.__finish_times
    return achievement_record
end

function RecordObject:check_limit_timestamp(limit_timestamp)
    return self.__timestamp >= limit_timestamp
end

function RecordObject:get_finish_times()
    return self.__finish_times
end

return RecordObject