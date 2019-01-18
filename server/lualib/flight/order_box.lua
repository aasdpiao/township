local class = require "class"

local OrderBox = class()

local order_status = {}
order_status.empty = 0
order_status.full = 1
order_status.help = 2
order_status.help_full = 3
order_status.help_confirm = 4

function OrderBox:ctor(role_object,order_index,item_count)
    self.__role_object = role_object
    self.__order_index = order_index
    self.__order_entry = role_object:get_flight_ruler():get_order_entry(order_index)
    self.__item_count = item_count
    self.__status = order_status.empty
    self.__role_id = 0
end

function OrderBox:dump_order_box()
    local order_box = {}
    order_box.order_index = self.__order_index
    order_box.item_count = self.__item_count
    order_box.status = self.__status
    order_box.role_id = self.__role_id
    return order_box
end

function OrderBox:set_role_id(role_id)
    self.__role_id = role_id
end

function OrderBox:get_item_index()
    return self.__order_entry:get_item_index()
end

function OrderBox:get_item_count()
    return self.__item_count
end

function OrderBox:get_order_value()
    return self.__order_entry:get_order_value() * self.__item_count
end

function OrderBox:get_order_exp()
    return self.__order_entry:get_order_exp() * self.__item_count
end

function OrderBox:get_friendly()
    local item_entry = self.__role_object:get_item_ruler():get_item_entry(self:get_item_index())
    return item_entry:get_friendly() * self.__item_count
end

function OrderBox:finish_order()
    self.__status = order_status.full
end

function OrderBox:check_can_request_help()
    return self.__status == order_status.empty
end

function OrderBox:finish_order_help(account_id)
    self.__status = order_status.help_full
    self.__role_id = account_id
end

function OrderBox:confirm_flight_help()
    self.__status = order_status.help_confirm
end

function OrderBox:is_help()
    return self.__status == order_status.help
end

function OrderBox:check_order_finish()
    return self.__status == order_status.full or self.__status >= order_status.help_full
end

function OrderBox:set_status(status)
    self.__status = status
end

function OrderBox:set_request_help()
    self.__status = order_status.help
end

return OrderBox