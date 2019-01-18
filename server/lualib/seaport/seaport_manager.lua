local class = require "class"
local datacenter = require "skynet.datacenter"
local IslandEntry = require "seaport.island_entry"
local ShipEntry = require "seaport.ship_entry"
local RewardEntry = require "seaport.reward_entry"
local IslandObject = require "seaport.island_object"
local RewardObject = require "seaport.reward_object"
local utils = require "utils"
local syslog = require "syslog"

local SeaportManager = class()

function SeaportManager:ctor(role_object)
    self.__role_object = role_object

    self.__island_entrys = {}
    self.__reward_entrys = {{},{},{},{}}
    self.__ship_entrys = {}
end

function SeaportManager:init()
    self:load_island_config()
    self:load_ship_config()
    self:load_reward_config()
end

function SeaportManager:load_ship_config()
    for build_id = 5008001,5008004 do
        local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
        local ship_entry = ShipEntry.new(unlock_entry)
        self.__ship_entrys[build_id] = ship_entry
    end
end

function SeaportManager:get_ship_entry(ship_index)
    return self.__ship_entrys[ship_index]
end

function SeaportManager:load_reward_config()
    local island_reward_config = datacenter.get("island_reward_config")
    for k,v in pairs(island_reward_config) do
        local reward_index = v.index
        local reward_type = v.reward_type
        local reward_entry = RewardEntry.new(v)
        self.__reward_entrys[reward_type][reward_index] = reward_entry
    end
end

function SeaportManager:get_gold_entry()
    for k,v in pairs(self.__reward_entrys[4]) do
        return v
    end
end

function SeaportManager:get_reward_entry(reward_index)
    for i=1,4 do
        local reward_entrys = self.__reward_entrys[i]
        local reward_entry = reward_entrys[reward_index]
        if reward_entry then return reward_entry end
    end
end

function SeaportManager:load_island_config()
    local island_config = datacenter.get("island_config")
    for k,v in pairs(island_config) do
        local island_index = v.index
        local island_entry = IslandEntry.new(v)
        self.__island_entrys[island_index] = island_entry
    end
end

function SeaportManager:get_island_entry(island_index)
    return self.__island_entrys[island_index]
end

function SeaportManager:generate_island_objects()
    local island_objects = {}
    for k,v in pairs(self.__island_entrys) do
        local island_index = v:get_island_index()
        local island_object = IslandObject.new(self.__role_object,v)
        island_object:init_island_object()
        island_objects[island_index] = island_object
    end
    return island_objects
end

function SeaportManager:generate_reward_objects()
    local level = self.__role_object:get_level()
    local reward_objects = {}
    for i=1,3 do
        local reward_entrys = self.__reward_entrys[i]
        local total_weight = 0
        local value_weight_list = {}
        for k,v in pairs(reward_entrys) do
            if v:check_level(level) then
                local weight = v:get_weight()
                local reward_index = v:get_reward_index()
                total_weight = total_weight + weight
                table.insert( value_weight_list, {reward_index,weight} )
            end
        end
        local reward_index = utils.get_random_value_in_weight(total_weight,value_weight_list)
        local reward_entry = self.__reward_entrys[i][reward_index]
        local reward_object = RewardObject.new(self.__role_object,reward_entry)
        reward_object:init_reward_object()
        reward_objects[i] = reward_object
    end
    return reward_objects
end

return SeaportManager