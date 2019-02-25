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

function RoleManager:gen_day_times_reward()
    local item_list = {5001,5002,5003,5004,5005,5006,5007,5008,5009}
    local total_weight = 0
    local value_weight_list = {}
    local count = 3
    for i,v in ipairs(item_list) do
        total_weight = total_weight + 10
        table.insert(value_weight_list,{v,10})
    end
    local select = utils.get_random_list_in_weight(total_weight,value_weight_list,count)
    local gem_list = {{3001,10},{3002,10},{3003,10},{3004,10}}
    local gem_index = utils.get_random_value_in_weight(40,gem_list)
    local worker_object = self.__role_object:get_employ_ruler():gen_worker_object(3001)
    local day_times_reward = {}
    day_times_reward[1] = {item = {item_index=7001,item_count=200}}
    day_times_reward[2] = {item = {item_index=select[1],item_count=1}}
    day_times_reward[3] = {item = {item_index=7003,item_count=10}}
    day_times_reward[4] = {item = {item_index=select[2],item_count=2}}
    day_times_reward[5] = {item = {item_index=7002,item_count=10}}
    day_times_reward[6] = {item = {item_index=select[3],item_count=3}}
    day_times_reward[7] = {item = {item_index=gem_index,item_count=1},
                        additional = {lock = {item_index = 7002,item_count = 20}, unlock = worker_object:dump_worker_object()}}
    return day_times_reward
end

return RoleManager