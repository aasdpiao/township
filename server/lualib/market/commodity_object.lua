local class = require "class"

local CommodityObject = class()

function CommodityObject:ctor(role_object,sale_index,item_count)
    self.__role_object = role_object
    local market_ruler = role_object:get_market_ruler()
    self.__sale_entry = market_ruler:get_sale_entry(sale_index)
    self.__sale_index = sale_index
    self.__item_count = item_count
end

function CommodityObject:dump_commodity_object()
    local commodity_object = {}
    commodity_object.sale_index = self.__sale_index
    commodity_object.item_count = self.__item_count
    return commodity_object
end

function CommodityObject:get_sale_index()
    return self.__sale_index
end

function CommodityObject:get_item_count()
    return self.__item_count
end

function CommodityObject:get_sale_price()
    return self.__sale_entry:get_sale_price()
end

function CommodityObject:get_item_index()
    return self.__sale_entry:get_item_index()
end

return CommodityObject
