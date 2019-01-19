local class = require "class"
local datacenter = require "skynet.datacenter"
local EventEntry = require "event.event_entry"
local utils = require "utils"

local EventManager = class()

function EventManager:ctor(role_object)
    self.__role_object = role_object

    self.__event_entrys = {}
end

function EventManager:init()
    local passerby_order_config = datacenter.get("passerby_order_config")
    for k,v in pairs(passerby_order_config) do
        local order_index = v.order_index
        local event_entry = EventEntry.new(order_index,v)
        self.__event_entrys[order_index] = event_entry
    end
end

function EventManager:get_event_entry(order_index)
    return self.__event_entrys[order_index]
end

function EventManager:get_event_upper()
    local event_upper = self.__role_object:get_role_entry():get_event_upper()
    return event_upper
end

function EventManager:generate_order_index()
    local level = self.__role_object:get_level()
    local total_weight = 0
    local value_weight_list = {}
    for k,v in pairs(self.__event_entrys) do
        if v:check_level(level) then
            local order_weight = v:get_order_weight()
            total_weight = total_weight + order_weight
            table.insert( value_weight_list, {k,order_weight})
        end
    end
    local order_index = utils.get_random_value_in_weight(total_weight,value_weight_list)
    return order_index
end

return EventManager