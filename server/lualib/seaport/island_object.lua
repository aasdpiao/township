local class = require "class"
local RewardObject = require "seaport.reward_object"

local DELTIME = 30 * 60

local IslandObject = class()

function IslandObject:ctor(role_object,island_entry)
    self.__role_object = role_object
    self.__island_entry = island_entry
    self.__island_index = island_entry:get_island_index()
    self.__ship_index = 0
    self.__multiple = 0
    self.__reward_objects = {}
    self.__timestamp = 0
    self.__status = 0
end

function IslandObject:load_island_object(island_object)
    self.__multiple = island_object.multiple
    self.__timestamp = island_object.timestamp
    self.__status = island_object.status
    self.__ship_index = island_object.ship_index
    local reward_objects = island_object.reward_objects or {}
    self:load_reward_objects(reward_objects)
end

function IslandObject:load_reward_objects(reward_objects)
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

function IslandObject:dump_island_object()
    local island_object = {}
    island_object.island_index = self.__island_index
    island_object.multiple = self.__multiple
    island_object.timestamp = self.__timestamp
    island_object.status = self.__status
    island_object.ship_index = self.__ship_index
    island_object.reward_objects = self:dump_reward_objects()
    return island_object
end

function IslandObject:dump_reward_objects()
    local reward_objects = {}
    for i,v in ipairs(self.__reward_objects) do
        reward_objects[i] = v:dump_reward_object()
    end
    return reward_objects
end

function IslandObject:init_island_object()
    self:generate_multiple()
    self:generate_reward_objects()
end

function IslandObject:check_can_refresh(timestamp)
    if self.__status == 1 then 
        return self.__timestamp + DELTIME <= timestamp
    end
    return self.__ship_index == 0
end

function IslandObject:generate_reward_objects()
    local seaport_manager = self.__role_object:get_seaport_ruler():get_seaport_manager()
    self.__reward_objects = seaport_manager:generate_reward_objects()
end

function IslandObject:generate_multiple()
    self.__multiple = self.__island_entry:generate_multiple()
end

function IslandObject:get_multiple()
    return self.__multiple
end

function IslandObject:get_island_index()
    return self.__island_index
end

function IslandObject:get_set_sail_gold()
    return self.__island_entry:get_need_gold()
end

function IslandObject:get_finish_time()
    return self.__island_entry:get_finish_time()
end

function IslandObject:set_ship_index(ship_index)
    self.__ship_index = ship_index
end

function IslandObject:set_sail(timestamp)
    self.__timestamp = timestamp  + self:get_finish_time()
    self:init_island_object()
end

function IslandObject:check_can_set_sail(timestamp)
    if self.__status == 1 then
        if self.__timestamp + DELTIME > timestamp then return false end
        self.__status = 0
        return true
    else
        if self.__ship_index == 0 then return true end
        if self.__timestamp > timestamp then return false end
        self.__ship_index = 0
        return true
    end
end

function IslandObject:check_can_promote(timestamp)
    if self.__status ~= 1 then return false end
    return self.__timestamp + DELTIME > timestamp
end

function IslandObject:get_remain_time(timestamp)
    return self.__timestamp + DELTIME - timestamp
end

function IslandObject:get_reward_objects()
    return self.__reward_objects
end

function IslandObject:harvest_ship()
    self.__ship_index = 0
end

function IslandObject:refresh_harbor(timestamp)
    self:init_island_object()
    self.__status = 1 
    self.__timestamp = timestamp
end

function IslandObject:promote_harbor()
    self.__status = 0
    self.__timestamp = 0
end

return IslandObject