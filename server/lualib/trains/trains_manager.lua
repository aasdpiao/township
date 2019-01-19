local class = require "class"
local datacenter = require "skynet.datacenter"
local TrainsEntry = require "trains.trains_entry"
local OrderEntry = require "trains.order_entry"
local RewardEntry = require "trains.reward_entry"
local TerminalEntry = require "trains.terminal_entry"
local utils = require "utils"

local TrainsManager = class()

function TrainsManager:ctor()
    self.__trains_entrys = {}
    self.__order_entrys = {}
    self.__reward_entrys = {}
    self.__terminal_entrys = {}
end

function TrainsManager:init()
    self.load_trains_config(self)
    self.load_order_config(self)
    self.load_reward_config(self)
    self.load_terminal_config(self)
end

function TrainsManager:load_terminal_config()
    local terminal_config = datacenter.get("terminal_config")
    for k,terminal_object in pairs(terminal_config) do
        local terminal_index = terminal_object.index
        local terminal_entry = TerminalEntry.new(terminal_object)
        self.__terminal_entrys[terminal_index] = terminal_entry
    end
end

function TrainsManager:get_terminal_entry(terminal_index)
    return self.__terminal_entrys[terminal_index]
end

function TrainsManager:load_reward_config()
    local trains_reward = datacenter.get("trains_reward")
    for k,reward_config in pairs(trains_reward) do
        local reward_index = reward_config.reward_index
        local reward_entry = RewardEntry.new(reward_config)
        self.__reward_entrys[reward_index] = reward_entry
    end
end

function TrainsManager:get_reward_entry(reward_index)
    return self.__reward_entrys[reward_index]
end

function TrainsManager:load_order_config()
    local trains_order_config = datacenter.get("trains_order_config")
    for k,order_config in pairs(trains_order_config) do
        local order_index = order_config.order_index
        local order_entry = OrderEntry.new(order_config)
        self.__order_entrys[order_index] = order_entry
    end
end

function TrainsManager:get_order_entry(order_index)
    return self.__order_entrys[order_index]
end

function TrainsManager:load_trains_config()
    local trains_config = datacenter.get("trains_config")
    for k,trains_data in pairs(trains_config) do
        local trains_index = trains_data.trains_index
        local trains_entry = TrainsEntry.new(trains_data)
        self.__trains_entrys[trains_index] = trains_entry
    end
end

function TrainsManager:get_trains_entry(trains_index)
    return self.__trains_entrys[trains_index]
end

function TrainsManager:get_trains_entrys()
    return self.__trains_entrys
end

function TrainsManager:get_trains_orders(role_object)
    local total_weight = 0
    local availables = {}
    for k,v in pairs(self.__order_entrys) do
        if v:check_order_available(role_object) then
            total_weight = total_weight + v:get_order_weight()
            table.insert(availables,{v:get_order_index(),v:get_order_weight()})
        end
    end
    local cars_weight = role_object:get_role_entry():get_cars_total_weight()
    local num_cars = role_object:get_role_entry():get_num_cars()
    local count = utils.get_random_value_in_weight(cars_weight,num_cars)
    local result = {}
    for i=1,count do
        local order_index = utils.get_random_value_in_weight(total_weight,availables)
        table.insert(result,order_index)
    end
    return result
end

function TrainsManager:get_trains_rewards(role_object,count)
    local total_weight = 0
    local availables = {}
    for k,v in pairs(self.__reward_entrys) do
        if v:check_reward_available(role_object) then
            total_weight = total_weight + v:get_reward_weight()
            table.insert(availables,{v:get_reward_index(),v:get_reward_weight()})
        end
    end
    local result = {}
    for i=1,count do
        local reward_index = utils.get_random_value_in_weight(total_weight,availables)
        table.insert(result,reward_index)
    end
    return result
end

function TrainsManager:get_terminal_index(role_object)
    local total_weight = 0
    local availables = {}
    for k,terminal_entry in pairs(self.__terminal_entrys) do
        if terminal_entry:check_terminal_available(role_object) then
            local terminal_weight = terminal_entry:get_terminal_weight()
            local terminal_index = terminal_entry:get_terminal_index()
            total_weight = total_weight + terminal_weight
            table.insert(availables,{terminal_index,terminal_weight})
        end
    end
    return utils.get_random_value_in_weight(total_weight,availables)
end

return TrainsManager