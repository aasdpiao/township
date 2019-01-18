local class = require "class"
local OrderBox = require "helicopter.order_box"

local OrderObject = class()

local DELETETIME = 30 * 60

function OrderObject:ctor(role_object,order_boxes)
    self.__role_object = role_object
    self.__order_boxes = {}
    for i,v in ipairs(order_boxes) do
        local order_index = v.order_index
        local item_count = v.item_count
        local order_box = OrderBox.new(role_object,order_index,item_count)
        self.__order_boxes[i] = order_box
    end
    self.__person_index = 0
    self.__timestamp = 0
    self.__status = 0
end

function OrderObject:dump_order_object()
    local order_object = {}
    order_object.order_boxes = self:dump_order_boxes()
    order_object.person_index = self.__person_index
    order_object.timestamp = self.__timestamp
    order_object.status = self.__status
    return order_object
end

function OrderObject:dump_order_boxes()
    local order_boxes = {}
    for i,v in ipairs(self.__order_boxes) do
        order_boxes[i] = v:dump_order_box()
    end
    return order_boxes
end

function OrderObject:get_order_boxes()
    return self.__order_boxes
end

function OrderObject:set_person_index(person_index)
    self.__person_index = person_index
end

function OrderObject:get_person_index()
    return self.__person_index
end

function OrderObject:set_timestamp(timestamp)
    self.__timestamp = timestamp
end

function OrderObject:get_timestamp()
    return self.__timestamp
end

function OrderObject:set_status(status)
    self.__status = status
end

function OrderObject:get_status()
    return self.__status
end

function OrderObject:check_can_delete(timestamp)
    return self.__status == 0 or (self.__status == 1 and (self.__timestamp <= timestamp))
end

function OrderObject:check_can_finish(timestamp)
    if self.__status == 0 then return true end
    return self.__timestamp <= timestamp
end

function OrderObject:check_can_promote(timestamp)
    return self.__status == 1 and self.__timestamp > timestamp
end

return OrderObject