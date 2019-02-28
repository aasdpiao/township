local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"
local CMD = require "role.admin_power"

local PlantDispatcher = class()

function PlantDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function PlantDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function PlantDispatcher:init()
    self:register_c2s_callback("planting_cropper",self.dispatcher_planting_cropper)
    self:register_c2s_callback("harvest_cropper",self.dispatcher_harvest_cropper)
    self:register_c2s_callback("promote_plant",self.dispatcher_promote_plant)
    self:register_c2s_callback("create_cloud",self.dispatcher_create_cloud)
    self:register_c2s_callback("use_cloud",self.dispatcher_use_cloud)
    self:register_c2s_callback("watering",self.dispatcher_watering)
end

function PlantDispatcher.dispatcher_watering(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local build_id = msg_data.build_id
    local account_id = msg_data.account_id
    role_object:refresh_kattle(timestamp)
    if not role_object:check_can_watering() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_watering))
        return {result=GAME_ERROR.cant_watering}
    end
    local result,friendly =  role_object:get_cache_ruler():watering(account_id,build_id,timestamp)
    if result == 0 then
        role_object:consume_kettle_times()
        role_object:add_friendly(friendly,SOURCE_CODE.help)
        role_object:get_daily_ruler():help_plant()
        role_object:get_daily_ruler():seven_help_water()
    end
    return {result = result}
end

--生成云朵
function PlantDispatcher.dispatcher_create_cloud(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local result = role_object:get_plant_ruler():create_cloud(timestamp)
    local timestamp = role_object:get_plant_ruler():get_next_refresh_timestamp()
    local cloud_count = role_object:get_plant_ruler():get_cloud_count()
    return {result = result,cloud_count = cloud_count,timestamp = timestamp}
end

--使用云朵
function PlantDispatcher.dispatcher_use_cloud(role_object,msg_data)
    local build_id = msg_data.build_id
    local timestamp = msg_data.timestamp
    local result = role_object:get_plant_ruler():promote_plant_by_cloud(build_id,timestamp)
    local timestamp = role_object:get_plant_ruler():get_next_refresh_timestamp()
    local cloud_count = role_object:get_plant_ruler():get_cloud_count()
    return {result = result,cloud_count = cloud_count,timestamp = timestamp}
end

--种田
function PlantDispatcher.dispatcher_planting_cropper(role_object,msg_data)
    local plant_objects = msg_data.plant_objects
    for i,v in ipairs(plant_objects) do
        local timestamp = v.timestamp
        local build_id = v.build_id
        local plant_index = v.plant_index
        local result = role_object:get_plant_ruler():planting_products(build_id,plant_index,timestamp)
        if result ~= 0 then
            return {result = result}
        end
    end
    return {result = 0}
end

--收农产品
function PlantDispatcher.dispatcher_harvest_cropper(role_object,msg_data)
    local plant_objects = msg_data.plant_objects
    for i,v in ipairs(plant_objects) do
        local timestamp = v.timestamp
        local build_id = v.build_id
        local result = role_object:get_plant_ruler():harvest_products(build_id,timestamp)
        if result ~= 0 then
            return {result = result}
        end
    end
    return {result=0}
end

--种植加速
function PlantDispatcher.dispatcher_promote_plant(role_object,msg_data)
    local build_id = msg_data.build_id
    local timestamp = msg_data.timestamp
    local cash_count = msg_data.cash_count
    local result = role_object:get_plant_ruler():promote_plant(build_id,cash_count,timestamp)
    return {result = result}
end

return PlantDispatcher

