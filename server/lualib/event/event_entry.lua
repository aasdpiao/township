
local class = require "class"
local EventEntry = class()

function EventEntry:ctor(order_index,order_config)
    self.__order_index = order_index
    self.__item_index = order_config.item_index
    self.__item_count = order_config.item_count
    self.__order_weight = order_config.order_weight
    self.__unlock_level = order_config.unlock_level
    self.__order_exp = order_config.order_exp
    self.__order_gold = order_config.order_gold
end

function EventEntry:check_level(level)
    return self.__unlock_level <= level
end

function EventEntry:get_order_weight()
    return self.__order_weight
end

function EventEntry:get_item_index()
    return self.__item_index
end

function EventEntry:get_item_count()
    return self.__item_count
end

function EventEntry:get_order_exp()
    return self.__order_exp
end

function EventEntry:get_order_gold()
    return self.__order_gold
end

return EventEntry
