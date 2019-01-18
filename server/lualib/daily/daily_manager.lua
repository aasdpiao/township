local class = require "class"
local utils = require "utils"
local datacenter = require "skynet.datacenter"
local TaskEntry = require "daily.task_entry"
local RewardEntry = require "daily.reward_entry"
local TaskObject = require "daily.task_object"
local RewardObject = require "daily.reward_object"

local DailyManager = class()

function DailyManager:ctor(role_object)
    self.__role_object = role_object
    self.__task_entrys = {}
    self.__reward_entrys = {}

    self.__total_weight = {0,0}
    self.__value_weight_list = {{},{}}
end

function DailyManager:init()
    self:load_daily_config()
    self:load_reward_config()
end

function DailyManager:load_daily_config(  )
    local daily_config = datacenter.get("daily_config")
    for k,v in pairs(daily_config) do
        local task_index = v.task_index
        local task_entry = TaskEntry.new(task_index)
        task_entry:load_task_entry(v)
        self.__task_entrys[task_index] = task_entry
    end
end

function DailyManager:get_task_entry(task_index)
    return self.__task_entrys[task_index]
end

function DailyManager:load_reward_config(  )
    local daily_reward_config = datacenter.get("daily_reward_config")
    for k,v in pairs(daily_reward_config) do
        local reward_index = v.reward_index
        local reward_entry = RewardEntry.new(reward_index)
        reward_entry:load_reward_entry(v)
        self.__reward_entrys[reward_index] = reward_entry
        local reward_type = reward_entry:get_reward_type()
        local weight = reward_entry:get_random_weight()
        self.__total_weight[reward_type] = self.__total_weight[reward_type] + weight
        table.insert(self.__value_weight_list[reward_type],{reward_index,weight})
    end
end

function DailyManager:get_reward_entry(reward_index)
    return self.__reward_entrys[reward_index]
end

function DailyManager:generate_task_objects()
    local task_objects = {}
    local level = self.__role_object:get_level()
    local total_weight = 0
    local value_weight_list = {}
    for k,v in pairs(self.__task_entrys) do
        if v:check_unlock_level(level) then
            local task_index = v:get_task_index()
            local weight = v:get_random_weight()
            total_weight = total_weight + weight
            table.insert(value_weight_list,{task_index,weight})
        end
    end
    local task_list = utils.get_random_list_in_weight(total_weight,value_weight_list,9)
    for i,v in ipairs(task_list) do
        local task_object = TaskObject.new(self.__role_object)
        task_object:set_task_index(v)
        task_objects[i] = task_object
    end
    return task_objects
end

function DailyManager:generate_reward_objects()
    local reward_objects = {}
    local total_weight = self.__total_weight[1]
    local value_weight_list = self.__value_weight_list[1]
    local reward_objects = utils.get_random_list_in_weight(total_weight,value_weight_list,6)
    for i,v in ipairs(reward_objects) do
        local reward_object = RewardObject.new(self.__role_object)
        reward_object:set_reward_index(v)
        reward_objects[i] = reward_object
    end
    total_weight = self.__total_weight[2]
    value_weight_list = self.__value_weight_list[2]
    local reward_index = utils.get_random_value_in_weight(total_weight,value_weight_list)
    local reward_object = RewardObject.new(self.__role_object)
    reward_object:set_reward_index(reward_index)
    reward_objects[7] = reward_object
    return reward_objects
end

return DailyManager