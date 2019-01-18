local OrderEntry = class()
local utils = require "utils"

function OrderEntry:ctor(order_config)
    self.__order_index = order_config.order_index
    self.__item_index = order_config.item_index
    self.__order_weight = order_config.order_weight
    self.__unlock_level = order_config.unlock_level
    self.__order_price = order_config.order_price
    local random_min = order_config.random_min
    local random_max = order_config.random_max
    self.__random_count = {{random_min[1],random_max[1]},{random_min[2],random_max[2]},{random_min[3],random_max[3]}}
    local counts = order_config.counts
    local count_weight = order_config.count_weight
    self.__count_weights = {}
    self.__total_weight = 0
    for i,v in ipairs(counts) do
        local weight = count_weight[i]
        self.__count_weights[i] = {v,weight}
        self.__total_weight = self.__total_weight + weight
    end
end

function OrderEntry:generate_employ_count()
    local count1 = utils.get_random_int(self.__random_count[1][1],self.__random_count[1][2])
    local count2 = utils.get_random_int(self.__random_count[2][1],self.__random_count[2][2])
    local count3 = utils.get_random_int(self.__random_count[3][1],self.__random_count[3][2])
    return {count1,count2,count3}
end

function OrderEntry:generate_count()
    return utils.get_random_value_in_weight(self.__total_weight,self.__count_weights)
end

function OrderEntry:get_order_price()
    return self.__order_price
end

function OrderEntry:check_level(level)
    return self.__unlock_level <= level
end

function OrderEntry:get_order_weight()
    return self.__order_weight
end

return OrderEntry