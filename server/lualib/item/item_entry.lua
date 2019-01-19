local class = require("class")

local ItemEntry = class()

function ItemEntry:ctor(item_index)
    self.__item_index = item_index
    self.__item_attr = {}
end

function ItemEntry:init_item_entry(item_attr)
    self.__item_attr = item_attr
end

function ItemEntry:get_item_index()
    return self.__item_index
end

function ItemEntry:get_cash_count()
    return self.__item_attr.cash_price
end

function ItemEntry:get_sale_price()
    return self.__item_attr.sale_price
end

function ItemEntry:get_item_name()
    return self.__item_attr.item_name
end

function ItemEntry:get_trains_exp()
    return self.__item_attr.trainexp
end

function ItemEntry:get_friendly()
    return self.__item_attr.friendly or 0
end

return ItemEntry