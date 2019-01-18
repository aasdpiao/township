local class = require "class"
local datacenter = require "skynet.datacenter"
local OrderEntry = require "flight.order_entry"
local RewardEntry = require "flight.reward_entry"
local utils = require "utils"
local syslog = require "syslog"

local FlightManager = class()

function FlightManager:ctor(role_object)
    self.__role_object = role_object

    self.__order_entrys = {}
    self.__reward_entrys = {{},{},{}}
end

function FlightManager:init()
    self:load_order_config()
    self:load_reward_config()
end

function FlightManager:load_reward_config()
    local flight_reward_config = datacenter.get("flight_reward_config")
    for i,v in pairs(flight_reward_config) do
        local reward_index = v.index
        local reward_type = v.type
        local item_index = v.item_index
        local item_count = v.item_count
        local unlock_level = v.unlock_level
        local weight = v.order_weight
        local reward_entry = RewardEntry.new(reward_index,item_index,item_count,unlock_level,weight)
        self.__reward_entrys[reward_type][reward_index] = reward_entry
    end
end

function FlightManager:load_order_config()
    local flight_order_config = datacenter.get("flight_order_config")
    for k,v in pairs(flight_order_config) do
        local order_index = v.order_index
        local order_entry = OrderEntry.new(v)
        self.__order_entrys[order_index] = order_entry
    end
end

function FlightManager:get_order_entry(order_index)
    return self.__order_entrys[order_index]
end

function FlightManager:gen_order_entry()
    local level = self.__role_object:get_level()
    local total_weight = 0
    local order_list = {}
    for order_index,order_entry in pairs(self.__order_entrys) do
        local unlock_level = order_entry:get_unlock_level()
        local weight = order_entry:get_order_weight()
        if unlock_level <= level then
            table.insert( order_list, {order_index,weight} )
            total_weight = total_weight + weight
        end
    end
    local order_index = utils.get_random_value_in_weight(total_weight,order_list)
    return order_index
end

function FlightManager:generate_flight_order()
    local exp = self.__role_object:get_role_entry():get_flight_exp()
    local count = utils.get_random_int(2,3)
    local order_exp = math.ceil(exp/count)
    local orders = {}
    for i=1,count do
        local order_index = self:gen_order_entry()
        local order_entry = self:get_order_entry(order_index)
        local item_exp = order_entry:get_order_exp()
        local item_count = math.ceil( order_exp/item_exp )
        table.insert(orders,{order_index=order_index,item_count=item_count})
    end
    return orders
end

function FlightManager:generate_rewards()
    local level = self.__role_object:get_level()
    local reward_items = {}
    for i=1,3 do
        local rewards = self.__reward_entrys[i]
        local reward_entrys = {}
        local total_weight = 0
        for k,v in pairs(rewards) do
            if v:check_level(level) then
                local reward_index = v:get_reward_index()
                local weight = v:get_weight()
                total_weight = total_weight + weight
                table.insert( reward_entrys, {reward_index, weight} )
            end
        end
        local reward_index = utils.get_random_value_in_weight(total_weight,reward_entrys)
        local reward_entry = rewards[reward_index]
        reward_items[i] = {item_index=reward_entry:get_item_index(),item_count=reward_entry:get_item_count()}
    end
    return reward_items
end

return FlightManager