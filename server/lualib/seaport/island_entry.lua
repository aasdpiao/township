local class = require "class"
local utils =require "utils"

local IslandEntry = class()

function IslandEntry:ctor(island_config)
    self.__island_index = island_config.index
    self.__finish_time = island_config.finish_time
    self.__need_gold = island_config.need_gold
    self.__multiple = {}
    self.__total_weight = 0
    local sale_multiple = island_config.sale_multiple
    local multiple_weight = island_config.multiple_weight
    for i,v in ipairs(sale_multiple) do
        local weight = multiple_weight[i]
        self.__total_weight = self.__total_weight + weight
        self.__multiple[i] = {v, weight}
    end
end

function IslandEntry:get_island_index()
    return self.__island_index
end

function IslandEntry:generate_multiple()
    return utils.get_random_value_in_weight(self.__total_weight,self.__multiple)
end

function IslandEntry:get_need_gold()
    return self.__need_gold
end

function IslandEntry:get_finish_time()
    return self.__finish_time
end

return IslandEntry