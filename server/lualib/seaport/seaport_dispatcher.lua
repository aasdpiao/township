local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local SeaportDispatcher = class()

function SeaportDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function SeaportDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function SeaportDispatcher:init()
    self:register_c2s_callback("unlock_seaport",self.dispatcher_unlock_seaport)
    self:register_c2s_callback("promote_seaport",self.dispatcher_promote_seaport)
    self:register_c2s_callback("finish_seaport",self.dispatcher_finish_seaport)
    self:register_c2s_callback("set_sail",self.dispatcher_set_sail)
    self:register_c2s_callback("promote_set_sail",self.dispatcher_promote_set_sail)
    self:register_c2s_callback("harvest_ship",self.dispatcher_harvest_ship)
    self:register_c2s_callback("refresh_harbor",self.dispatcher_refresh_harbor)
    self:register_c2s_callback("promote_harbor",self.dispatcher_promote_harbor)
    self:register_c2s_callback("add_ship",self.dispatcher_add_ship)
end

function SeaportDispatcher.dispatcher_unlock_seaport(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local gold_count = msg_data.gold_count
    local seaport_ruler = role_object:get_seaport_ruler()
    local result = seaport_ruler:unlock_seaport(timestamp,gold_count)
    return {result = result}
end

function SeaportDispatcher.dispatcher_promote_seaport(role_object,msg_data)
    local timestamp = msg_data.timestamp 
    local cash_count = msg_data.cash_count
    local seaport_ruler = role_object:get_seaport_ruler()
    local result = seaport_ruler:promote_seaport(timestamp,cash_count)
    return {result = result}
end

function SeaportDispatcher.dispatcher_finish_seaport(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local item_objects = msg_data.item_objects or {}
    local seaport_ruler = role_object:get_seaport_ruler()
    local result = seaport_ruler:finish_seaport(timestamp,item_objects)
    local island_objects = seaport_ruler:dump_island_objects()
    local ship_objects = seaport_ruler:dump_ship_objects()
    return {result = result,island_objects = island_objects,ship_objects = ship_objects}
end

function SeaportDispatcher.dispatcher_set_sail(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local ship_index = msg_data.ship_index
    local gold_count = msg_data.gold_count
    local island_index = msg_data.island_index
    local commodity_objects = msg_data.commodity_objects or {}
    local seaport_ruler = role_object:get_seaport_ruler()
    local result = seaport_ruler:set_sail(ship_index,timestamp,island_index,gold_count,commodity_objects)
    local island_object = seaport_ruler:get_island_object(island_index):dump_island_object()
    local ship_object = seaport_ruler:get_ship_object(ship_index):dump_ship_object()
    return {result = result,island_object = island_object,ship_object=ship_object}
end

function SeaportDispatcher.dispatcher_promote_set_sail(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local ship_index = msg_data.ship_index
    local cash_count = msg_data.cash_count
    local seaport_ruler = role_object:get_seaport_ruler()
    local result = seaport_ruler:promote_set_sail(ship_index,timestamp,cash_count)
    return {result = result}
end

function SeaportDispatcher.dispatcher_harvest_ship(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local ship_index = msg_data.ship_index
    local reward_objects = msg_data.reward_objects
    local seaport_ruler = role_object:get_seaport_ruler()
    local result = seaport_ruler:harvest_ship(ship_index,timestamp,reward_objects)
    return {result = result}
end

function SeaportDispatcher.dispatcher_refresh_harbor(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local island_index = msg_data.island_index
    local seaport_ruler = role_object:get_seaport_ruler()
    local result = seaport_ruler:refresh_harbor(island_index,timestamp)
    local island_object = seaport_ruler:get_island_object(island_index):dump_island_object()
    return {result = result,island_object = island_object}
end

function SeaportDispatcher.dispatcher_promote_harbor(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local island_index = msg_data.island_index
    local cash_count = msg_data.cash_count
    local seaport_ruler = role_object:get_seaport_ruler()
    local result = seaport_ruler:promote_harbor(island_index,timestamp,cash_count)
    return {result = result}
end

function SeaportDispatcher.dispatcher_add_ship(role_object,msg_data)
    local ship_index = msg_data.ship_index
    local gold_count = msg_data.gold_count
    local seaport_ruler = role_object:get_seaport_ruler()
    local result = seaport_ruler:add_ship(ship_index,gold_count)
    return {result = result}
end

return SeaportDispatcher