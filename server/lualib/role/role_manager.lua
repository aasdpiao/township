local class = require "class"
local RoleEntry = require "role.role_entry"
local RoleDispatcher = require "role.role_dispatcher"
local datacenter = require "skynet.datacenter"
local utils = require "utils"
local RoleManager = class()

function RoleManager:ctor(role_object)
    self.__role_object = role_object
    self.__role_entrys = {}
    self.__speedup_cash = {}
    self.__sign_in = {}
    self.__sign_rewards = {}
    self.__sign_weights = {}
    self.__sign_total_weights = {}
end

function RoleManager:init()
    self.__role_dispatcher = RoleDispatcher.new(self.__role_object)
    self.__role_dispatcher:init()

    self.load_role_config(self)
    self.load_speedup_config(self)
    self.load_sign_in(self)
end

function RoleManager:load_sign_in()
    local sign_box_config = datacenter.get("sign_box_config")
    local sign_in_config = datacenter.get("sign_in_config")
    for k,v in pairs(sign_in_config) do
        local day = v.day
        local coin_count = v.coin_count
        self.__sign_in[day] = coin_count
    end
    for k,v in pairs(sign_box_config) do
        self.__sign_rewards[k] = v
        local weight = v.weight
        local index = v.index
        local type = v.type
        if not self.__sign_weights[type] then  
            self.__sign_weights[type] = {} 
            self.__sign_total_weights[type] = 0
        end
        table.insert(self.__sign_weights[type],{index,weight})
        self.__sign_total_weights[type] = self.__sign_total_weights[type] + weight
    end
end

function RoleManager:gen_sign_rewards()
    local rewrds = {}
    for i=1,3 do
        local index = utils.get_random_value_in_weight(self.__sign_total_weights[i],self.__sign_weights[i])
        local reward_entry = self.__sign_rewards[index]
        local item_index = reward_entry.item_index
        local item_count = reward_entry.item_count
        rewrds[i] = { item_index = item_index, item_count = item_count }
    end
    return rewrds
end

function RoleManager:get_sign_gold(index)
    return self.__sign_in[index] or 0
end

function RoleManager:load_speedup_config()
    local speedup_config = datacenter.get("speedup_config")
    for k,v in pairs(speedup_config) do
        local cash = v.cash
        local time = v.time
        self.__speedup_cash[cash] = time
    end
end

function RoleManager:get_time_cost(remain_time)
    local cash = 1
    while true do 
        local time = self.__speedup_cash[cash]
        if not time then return cash - 1 end
        if remain_time <= time then return cash end
        cash = cash + 1
    end
end

function RoleManager:load_role_config()
    local levelup_config = datacenter.get("levelup_config")
    for k,v in pairs(levelup_config) do
        local level = v.level
        local role_entry = RoleEntry.new(v)
        self.__role_entrys[level] = role_entry
    end
end

function RoleManager:get_role_entry(level)
    return self.__role_entrys[level]
end

return RoleManager