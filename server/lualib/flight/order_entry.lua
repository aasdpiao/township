local class = require "class"

local OrderEntry = class()

function OrderEntry:ctor(order_config)
    self.__order_index = order_config.order_index
    self.__item_index = order_config.item_index
    self.__order_weight = order_config.order_weight
    self.__unlock_level = order_config.unlock_level
    self.__order_exp = order_config.order_exp
    self.__order_value = order_config.order_coin
end

function OrderEntry:get_order_index()
    return self.__order_index
end

function OrderEntry:get_item_index()
    return self.__item_index
end

function OrderEntry:get_order_weight()
    return self.__order_weight
end

function OrderEntry:get_unlock_level()
    return self.__unlock_level
end

function OrderEntry:get_order_exp()
    return self.__order_exp
end

function OrderEntry:get_order_value()
    return self.__order_value
end

return OrderEntry