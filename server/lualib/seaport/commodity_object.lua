local class = require "class"

local CommodityObject = class()

function CommodityObject:ctor(role_object,item_index,item_count)
    self.__role_object = role_object
    self.__item_index = item_index
    self.__item_count = item_count
end

function CommodityObject:dump_commodity_object()
    local commodity_object = {}
    commodity_object.item_index = self.__item_index
    commodity_object.item_count = self.__item_count
    return commodity_object
end

function CommodityObject:get_item_index()
    return self.__item_index
end

function CommodityObject:get_item_count()
    return self.__item_count
end

return CommodityObject