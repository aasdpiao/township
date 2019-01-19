local class =require "class"
local CommodityObject = require "seaport.commodity_object"
local RewardObject = require "seaport.reward_object"

local ShipObject = class()

function ShipObject:ctor(role_object,ship_entry)
    self.__role_object = role_object
    self.__ship_entry = ship_entry
    self.__ship_index = ship_entry:get_ship_index()
    self.__commodity_objects = {}
    self.__reward_objects = {}
    self.__multiple = 0
    self.__island_index = 0
    self.__status = 0
    self.__timestamp = 0
end

function ShipObject:load_ship_object(ship_object)
    self.__status = ship_object.status or 0
    self.__timestamp = ship_object.timestamp or 0
    self.__island_index = ship_object.island_index or 0
    self.__multiple = ship_object.multiple or 0
    local commodity_objects = ship_object.commodity_objects or {}
    local reward_objects = ship_object.reward_objects or {}
    self:load_commodity_objects(commodity_objects)
    self:load_reward_objects(reward_objects)
end

function ShipObject:load_reward_objects(reward_objects)
    local seaport_manager = self.__role_object:get_seaport_ruler():get_seaport_manager()
    for i,v in ipairs(reward_objects) do
        local reward_index = v.reward_index
        local item_count = v.item_count
        local status = v.status
        local reward_entry = seaport_manager:get_reward_entry(reward_index)
        local reward_object = RewardObject.new(self.__role_object,reward_entry)
        reward_object:set_item_count(item_count)
        reward_object:set_status(status)
        self.__reward_objects[i] = reward_object
    end
end

function ShipObject:load_commodity_objects(commodity_objects)
    for i,v in ipairs(commodity_objects) do
        local item_index = v.item_index
        local item_count = v.item_count
        local commodity_object = CommodityObject.new(self.__role_object,item_index,item_count)
        self.__commodity_objects[i] = commodity_object
    end
end

function ShipObject:dump_ship_object()
    local ship_object = {}
    ship_object.ship_index = self.__ship_index
    ship_object.status = self.__status
    ship_object.timestamp = self.__timestamp
    ship_object.island_index = self.__island_index
    ship_object.multiple = self.__multiple
    ship_object.commodity_objects = self:dump_commodity_objects()
    ship_object.reward_objects = self:dump_reward_objects()
    return ship_object
end

function ShipObject:dump_commodity_objects()
    local commodity_objects = {}
    for i,v in ipairs(self.__commodity_objects) do
        commodity_objects[i] = v:dump_commodity_object()
    end
    return commodity_objects
end

function ShipObject:dump_reward_objects()
    local reward_objects = {}
    for i,v in ipairs(self.__reward_objects) do
        reward_objects[i] = v:dump_reward_object()
    end
    return reward_objects
end

function ShipObject:check_can_set_sail(timestamp)
    return self.__status == 0
end

function ShipObject:check_can_promote(timestamp)
    if self.__status ~= 1 then return false end
    local island_object = self.__role_object:get_seaport_ruler():get_island_object(self.__island_index)
    local finish_time = island_object:get_finish_time()
    return self.__timestamp + finish_time > timestamp 
end

function ShipObject:check_can_harvest(timestamp)
    if self.__status == 2 then return true end
    if self.__status ~= 1 then return false end
    local island_object = self.__role_object:get_seaport_ruler():get_island_object(self.__island_index)
    local finish_time = island_object:get_finish_time()
    return self.__timestamp + finish_time <= timestamp 
end

function ShipObject:check_harvest_finish()
    for i,v in ipairs(self.__reward_objects) do
        if v:get_status() == 0 then return false end
    end
    return true
end

function ShipObject:get_remain_time(timestamp)
    local island_object = self.__role_object:get_seaport_ruler():get_island_object(self.__island_index)
    local finish_time = island_object:get_finish_time()
    return self.__timestamp + finish_time - timestamp
end

function ShipObject:set_island_index(island_index)
    self.__island_index = island_index
end

function ShipObject:get_island_index()
    return self.__island_index
end

function ShipObject:set_commodity_objects(commodity_objects)
    for i,v in ipairs(commodity_objects) do
        local item_index = v.item_index
        local item_count = v.item_count
        local commodity_object = CommodityObject.new(self.__role_object,item_index,item_count)
        self.__commodity_objects[i] = commodity_object
    end
end

function ShipObject:set_reward_objects(reward_objects)
    self.__reward_objects = reward_objects
end

function ShipObject:set_multiple(multiple)
    self.__multiple = multiple
    local item_ruler = self.__role_object:get_item_ruler()
    local gold_count = 0
    for i,v in ipairs(self.__commodity_objects) do
        local item_index = v:get_item_index()
        local item_count = v:get_item_count()
        local item_entry = item_ruler:get_item_entry(item_index)
        local sale_price = item_entry:get_sale_price()
        gold_count = gold_count + (sale_price * item_count)
    end
    gold_count = math.floor( (gold_count * multiple / 100) + 0.5)
    local gold_entry = self.__role_object:get_seaport_ruler():get_gold_entry()
    local reward_object = RewardObject.new(self.__role_object,gold_entry)
    reward_object:set_item_count(gold_count)
    table.insert( self.__reward_objects,1,reward_object)
end

function ShipObject:get_exp_count()
    local exp_count = 0
    local reward_objects = self:get_reward_objects()
    for i,v in ipairs(reward_objects) do
        exp_count = exp_count + v:get_exp_count()
    end
    return exp_count
end

function ShipObject:set_sail(timestamp)
    self.__timestamp = timestamp
    self.__status = 1
end

function ShipObject:promote_set_sail()
    self.__status = 2
end

function ShipObject:get_reward_objects()
    return self.__reward_objects
end

function ShipObject:harvest_ship()
    self.__status = 0
    self.__island_index = 0
    self.__timestamp = 0
    self.__commodity_objects = {}
    self.__role_object:get_achievement_ruler():finish_ship_record()
end

return ShipObject