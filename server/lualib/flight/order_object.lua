local class = require "class"
local OrderBox = require "flight.order_box"

local OrderObject = class()

function OrderObject:ctor(role_object,order_objects)
    self.__role_object = role_object
    self.__order_boxes = {}
    for i,v in ipairs(order_objects) do
        local order_index = v.order_index
        local item_count = v.item_count
        local order_box = OrderBox.new(role_object,order_index,item_count)
        self.__order_boxes[i] = order_box
    end
end

function OrderObject:get_order_value()
    local order_value = 0
    for i,v in ipairs(self.__order_boxes) do
        local value = v:get_order_value()
        order_value = order_value + value
    end
    return order_value
end

function OrderObject:dump_order_boxes()
    local order_boxes = {}
    for i,v in ipairs(self.__order_boxes) do
        order_boxes[i] = v:dump_order_box()
    end
    return order_boxes
end

function OrderObject:load_order_boxes(order_boxes)
    for i,v in ipairs(order_boxes) do
        local order_index = v.order_index
        local item_count = v.item_count
        local status = v.status
        local role_id = v.role_id
        local order_box = OrderBox.new(self.__role_object,order_index,item_count)
        order_box:set_status(status)
        order_box:set_role_id(role_id)
        self.__order_boxes[i] = order_box
    end
end

function OrderObject:dump_order_object()
    local order_object = {}
    order_object.order_boxes = self:dump_order_boxes()
    return order_object
end

function OrderObject:check_order_finish()
    local status = true 
    for i,v in ipairs(self.__order_boxes) do
        status = status and v:check_order_finish()
    end
    return status
end

function OrderObject:check_can_help()
    for i,v in ipairs(self.__order_boxes) do
        if v:is_help() then return false end
    end
    return true
end

function OrderObject:get_order_box(column)
    return self.__order_boxes[column]
end

return OrderObject