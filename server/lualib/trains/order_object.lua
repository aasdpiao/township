local class = require "class"

local OrderObject = class()

local order_status = {}
order_status.empty = 1
order_status.full = 2
order_status.help = 3
order_status.help_full = 4
order_status.confirm_help = 5

function OrderObject:ctor(role_object,order_entry,item_index,item_count)
    self.__role_object = role_object
    self.__order_entry = order_entry
    self.__order_index = order_entry:get_order_index()
    self.__item_index = item_index
    self.__item_count = item_count
    self.__status = order_status.empty
    self.__role_id = 0
end

function OrderObject:get_order_entry()
    return self.__order_entry
end

function OrderObject:dump_order_object()
    local order_object = {}
    order_object.order_index = self.__order_index
    order_object.item_index = self.__item_index
    order_object.item_count = self.__item_count
    order_object.status = self.__status
    order_object.role_id = self.__role_id
    return order_object
end

function OrderObject:load_order_object(order_data)
    self.__status = order_data.status
    self.__role_id = order_data.role_id
end

function OrderObject:get_status()
    return self.__status
end

function OrderObject:set_role_id(role_id)
    self.__role_id = role_id
end

function OrderObject:check_can_finish()
    return self.__status == order_status.empty or self.__status == order_status.help
end

function OrderObject:check_can_help()
    return self.__status == order_status.empty
end

function OrderObject:is_help()
    return self.__status == order_status.help
end

function OrderObject:check_order_finish()
    return self.__status == order_status.full or self.__status == order_status.confirm_help
end

function OrderObject:finish_order_object()
    self.__status = order_status.full
end

function OrderObject:set_is_help()
    self.__status = order_status.help
end

function OrderObject:check_can_finish_order_help()
    return self.__status == order_status.help_full
end

function OrderObject:finish_order_help()
    self.__status = order_status.help_full
end

function OrderObject:confirm_order_help()
    self.__status = order_status.confirm_help
end

function OrderObject:get_item_index()
    return self.__item_index
end

function OrderObject:get_item_count()
    return self.__item_count
end

function OrderObject:get_order_exp()
    return self.__item_count * self.__order_entry:get_order_exp()
end

function OrderObject:get_friendly()
    local item_entry = self.__role_object:get_item_ruler():get_item_entry(self.__item_index)
    return item_entry:get_friendly() * self.__item_count
end

function OrderObject:debug_info()
    local order_info = ""
    order_info = order_info.."item_index:"..self.__item_index.."\n"
    order_info = order_info.."item_count:"..self.__item_count.."\n"
    order_info = order_info.."status:"..self.__status.."\n"
    return order_info
end

return OrderObject