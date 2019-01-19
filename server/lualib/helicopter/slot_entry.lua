local class = require "class"

local SlotEntry = class()

function SlotEntry:ctor(slot_config)
    self.__min_level = slot_config.min_level
    self.__max_level = slot_config.max_level
    self.__order_count = slot_config.order_count
end

function SlotEntry:check_level(level)
    return self.__min_level <= level and self.__max_level >= level
end

function SlotEntry:get_order_count()
    return self.__order_count
end

return SlotEntry