local class = require "class"

local OrderBox = class()

function OrderBox:ctor(role_object,order_index,item_count)
    self.__role_object = role_object
    self.__order_index = order_index
    self.__order_entry = role_object:get_helicopter_ruler():get_order_entry(order_index)
    self.__item_count = item_count
end

function OrderBox:dump_order_box()
    local order_box = {}
    order_box.order_index = self.__order_index
    order_box.item_count = self.__item_count
    return order_box
end

function OrderBox:get_item_index()
    return self.__order_entry:get_item_index()
end

function OrderBox:get_item_count()
    return self.__item_count
end

function OrderBox:get_sale_price()
    return self.__order_entry:get_order_gold() * self.__item_count
end

function OrderBox:get_sale_exp()
    return self.__order_entry:get_order_exp() * self.__item_count
end

return OrderBox