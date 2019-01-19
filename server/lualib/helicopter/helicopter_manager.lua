local class = require "class"
local SlotEntry = require "helicopter.slot_entry"
local OrderEntry = require "helicopter.order_entry"
local OrderObject = require "helicopter.order_object"
local PersonEntry = require "helicopter.person_entry"
local datacenter = require "skynet.datacenter"
local utils = require "utils"

local HelicopterManager = class()

function HelicopterManager:ctor(role_object)
    self.__role_object = role_object

    self.__slot_entrys = {}
    self.__order_entrys = {}
    self.__person_entrys = {}
end 

function HelicopterManager:init()
    self:load_count_config()
    self:load_order_config()
    self:load_person_config()
end

function HelicopterManager:load_count_config()
    local helicopter_count_config = datacenter.get("helicopter_count_config")
    for k,v in pairs(helicopter_count_config) do
        local index = v.index
        local slot_entry = SlotEntry.new(v)
        self.__slot_entrys[index] = slot_entry
    end
end

function HelicopterManager:load_order_config()
    local helicopter_order_config = datacenter.get("helicopter_order_config")
    for k,v in pairs(helicopter_order_config) do
        local order_index = v.order_index
        local order_entry = OrderEntry.new(v)
        self.__order_entrys[order_index] = order_entry
    end
end

function HelicopterManager:get_order_entry(order_index)
    return self.__order_entrys[order_index]
end

function HelicopterManager:load_person_config()
    local helicopter_person_config = datacenter.get("helicopter_person_config")
    for k,v in pairs(helicopter_person_config) do
        local index = v.index
        local person_entry = PersonEntry.new(v)
        self.__person_entrys[index] = person_entry
    end
end

function HelicopterManager:get_order_count()
    local level = self.__role_object:get_level()
    for i,v in ipairs(self.__slot_entrys) do
        if v:check_level(level) then return v:get_order_count() end
    end
    return self.__slot_entrys[#self.__slot_entrys]:get_order_count()
end

function HelicopterManager:generate_person_index(person_entrys)
    local persons = {}
    for k,v in pairs(self.__person_entrys) do
        local person_index = v:get_person_index()
        if not person_entrys[person_index] then
            table.insert( persons,person_index)
        end
    end
    local count = #persons
    local seed = utils.get_random_int(1,count)
    return persons[seed]
end

function HelicopterManager:generate_order_object()
    local level = self.__role_object:get_level()
    local helicopter_boxes = self.__role_object:get_role_entry():get_helicopter_boxes()
    local helicopter_total_weight = self.__role_object:get_role_entry():get_helicopter_total_weight()
    local count = utils.get_random_value_in_weight(helicopter_total_weight,helicopter_boxes)
    local order_entrys = {}
    local total_weight = 0
    for k,v in pairs(self.__order_entrys) do
        if v:check_level(level) then
            local order_index = v:get_order_index()
            local order_weight = v:get_order_weight()
            total_weight = total_weight + order_weight
            table.insert(order_entrys,{order_index,order_weight})
        end
    end
    local exp = self.__role_object:get_role_entry():get_helicopter_exp()
    local order_exp = math.ceil(exp/count)
    local order_boxes = {}
    for i=1,count do
        local order_index = utils.get_random_value_in_weight(total_weight,order_entrys)
        local order_entry = self:get_order_entry(order_index)
        local simple_exp = order_entry:get_order_exp()
        local item_count = math.ceil(order_exp/simple_exp)
        order_boxes[i] = {order_index=order_index,item_count=item_count}
    end
    local order_object = OrderObject.new(self.__role_object,order_boxes) 
    return order_object
end

return HelicopterManager