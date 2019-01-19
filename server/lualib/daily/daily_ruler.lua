local class = require "class"
local utils = require "utils"
local packer = require "db.packer"

local DailyManager = require "daily.daily_manager"
local DailyDispatcher = require "daily.daily_dispatcher"
local RewardObject = require "daily.reward_object"
local TaskObject = require "daily.task_object"
local task_const = require "daily.task_const"

local REWARDMAP = {}
REWARDMAP[1] = {1,2,3}
REWARDMAP[2] = {4,5,6}
REWARDMAP[3] = {7,8,9}
REWARDMAP[4] = {1,4,7}
REWARDMAP[5] = {2,5,8}
REWARDMAP[6] = {3,6,9}
REWARDMAP[7] = {1,2,3,4,5,6,7,8,9}

local DailyRuler = class()

function DailyRuler:ctor(role_object)
    self.__role_object = role_object
    
    self.__timestamp = 0
    self.__task_objects = {}
    self.__reward_objects = {}

    self.__task_map = {}
end

function DailyRuler:init()
    self.__daily_manager = DailyManager.new(self.__role_object)
    self.__daily_manager:init()
    
    self.__daily_dispatcher = DailyDispatcher.new(self.__role_object)
    self.__daily_dispatcher:init()
end

function DailyRuler:get_daily_manager()
    return self.__daily_manager
end

function DailyRuler:load_daily_data(daily_data)
    if not daily_data then return end
    local timestamp = daily_data.timestamp or 0
    local task_objects = daily_data.task_objects or {}
    local reward_objects = daily_data.reward_objects or {}
    for i,v in ipairs(task_objects) do
        local task_object = TaskObject.new(self.__role_object)
        task_object:load_task_object(v)
        self.__task_objects[i] = task_object
    end
    for i,v in ipairs(reward_objects) do
        local reward_object = RewardObject.new(self.__role_object)
        reward_object:load_reward_object(v)
        self.__reward_objects[i] = reward_object
    end
    self.__timestamp = timestamp 
end

function DailyRuler:serialize_daily_data()
    local daily_data = self.dump_daily_data(self)
    return packer.encode(daily_data)
end

function DailyRuler:dump_daily_data()
    local daily_data = {}
    daily_data.timestamp = self.__timestamp
    daily_data.task_objects = self:dump_task_objects()
    daily_data.reward_objects = self:dump_reward_objects()
    return daily_data
end

function DailyRuler:dump_task_objects()
    local task_objects = {}
    for i,v in ipairs(self.__task_objects) do
        task_objects[i] = v:dump_task_object()
    end
    return task_objects
end

function DailyRuler:dump_reward_objects()
    local reward_objects = {}
    for i,v in ipairs(self.__reward_objects) do
        reward_objects[i] = v:dump_reward_object()
    end
    return reward_objects
end

function DailyRuler:check_can_receive(reward_index)
    local task_list = REWARDMAP[reward_index]
    if not task_list then return false end
    for i,v in ipairs(task_list) do
        local task_object = self.__task_objects[v]
        if not task_object then return false end
        if not task_object:check_finish() then return false end 
    end
    return true
end

function DailyRuler:refresh_task_objects()
    self.__task_map = {}
    for i,v in ipairs(self.__task_objects) do
        local task_index = v:get_task_index()
        self.__task_map[task_index] = v
    end
end

function DailyRuler:refresh_daily(timestamp)
    if timestamp < self.__timestamp then return end
    local interval_timestamp = utils.get_interval_timestamp(timestamp)
    self.__timestamp = interval_timestamp
    self.__task_objects = self.__daily_manager:generate_task_objects()
    self.__reward_objects = self.__daily_manager:generate_reward_objects()
    self:refresh_task_objects()
end

function DailyRuler:receive_daily(reward_index)
    local reward_object = self.__reward_objects[reward_index]
    if not reward_object:check_can_receive() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_receive_daily))
        return GAME_ERROR.cant_receive_daily
    end
    if not self:check_can_receive(reward_index) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_receive_daily))
        return GAME_ERROR.cant_receive_daily
    end
    reward_object:receive_reward()
    return 0
end

function DailyRuler:finish_task(task_index)
    local task_object = self.__task_objects[task_index]
    if not task_object:check_can_finish() then
        LOG_ERROR("task_index:%d err:%s",task_index,errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    task_object:finish_task()
    return 0
end

function DailyRuler:finish_daily_task(task_index,count)
    local task_object = self.__task_map[task_index]
    if not task_object then return end
    count = count or 1
    task_object:add_times(count)
    if task_object:check_can_finish() then
        self.__role_object:send_request("task_finish",{task_index=task_index,times=task_object:get_times()})
    end
end

function DailyRuler:finish_trains()
    self:finish_daily_task(task_const.finish_trains)
end

function DailyRuler:help_trains()
    self:finish_daily_task(task_const.help_trains)
end

function DailyRuler:finish_flight()
    self:finish_daily_task(task_const.finish_flight)
end

function DailyRuler:help_flight()
    self:finish_daily_task(task_const.help_flight)
end

function DailyRuler:help_plant()
    self:finish_daily_task(task_const.help_plant)
end

function DailyRuler:thumb_up()
    self:finish_daily_task(task_const.thumb_up)
end

function DailyRuler:access_manor()
    self:finish_daily_task(task_const.access_manor)
end

function DailyRuler:factory_storage(count)
    self:finish_daily_task(task_const.factory_storage,count)
end

function DailyRuler:factory_product(count)
    self:finish_daily_task(task_const.factory_product,count)
end

function DailyRuler:market_buy(count)
    self:finish_daily_task(task_const.market_buy,count)
end

function DailyRuler:sale_item(count)
    self:finish_daily_task(task_const.sale_item,count)
end

function DailyRuler:feed_harvest()
    self:finish_daily_task(task_const.feed_harvest)
end

function DailyRuler:feed_animal()
    self:finish_daily_task(task_const.feed_animal)
end

function DailyRuler:plant_harvest()
    self:finish_daily_task(task_const.plant_harvest)
end

function DailyRuler:plant_crop()
    self:finish_daily_task(task_const.plant_crop)
end

function DailyRuler:build_decorations()
    self:finish_daily_task(task_const.build_decorations)
end

function DailyRuler:finish_helicopter()
    self:finish_daily_task(task_const.finish_helicopter)
end

function DailyRuler:refresh_helicopter()
    self:finish_daily_task(task_const.refresh_helicopter)
end

function DailyRuler:set_sail()
    self:finish_daily_task(task_const.set_sail)
end

function DailyRuler:harvest_ship(count)
    self:finish_daily_task(task_const.harvest_ship,count)
end

function DailyRuler:use_cash(count)
    self:finish_daily_task(task_const.use_cash,count)
end

function DailyRuler:help_pedestrian()
    self:finish_daily_task(task_const.help_pedestrian)
end

return DailyRuler