local class = require "class"

local PlantManager = require "plant.plant_manager"
local PlantObject = require "plant.plant_object"
local PlantDispatcher = require "plant.plant_dispatcher"
local plant_const = require "plant.plant_const"
local packer = require "db.packer"
local syslog = require "syslog"
local utils = require "utils"

local PlantRuler = class()

local MAX_CLOUD = 5
local WATERTIME = 30 * 60
local FRIENDLY = 5

function PlantRuler:ctor(role_object)
    self.__role_object = role_object
    self.__plant_objects = {}
    self.__worker_id = 0
    self.__timestamp = 0
    self.__cloud_count = 0
end

function PlantRuler:init()
    self.__plant_manager = PlantManager.new()
    self.__plant_manager:init()

    self.__plant_dispatcher = PlantDispatcher.new(self.__role_object)
    self.__plant_dispatcher:init()
end

function PlantRuler:load_plant_data(plant_data)
    if not plant_data then return end
    local code = packer.decode(plant_data)
    local plant_objects = code.plant_objects
    local worker_id = code.worker_id or 0
    self.__worker_id = worker_id
    self.__timestamp = code.timestamp
    self.__cloud_count = code.cloud_count
    for k,v in pairs(plant_objects) do
        local timestamp = v.timestamp
        local build_id = v.build_id
        local plant_index = v.plant_index
        local status = v.status
        local harvest_time = v.harvest_time
        local role_id = v.role_id
        local plant_object = self.get_plant_object(self,build_id)
        if plant_index > 0 then
            local plant_entry = self.__plant_manager:get_plant_entry(plant_index)
            plant_object:start_plant_crop(timestamp,plant_entry)
            plant_object:set_status(status)
            plant_object:set_harvest_time(harvest_time)
            plant_object:set_role_id(role_id)
        end
    end
end

function PlantRuler:dump_plant_data()
    local plant_data = {}
    plant_data.plant_objects = {}
    for k,v in pairs(self.__plant_objects) do
        if v:get_states() == plant_const.planting or v:get_states() == plant_const.promote then
            table.insert(plant_data.plant_objects,v:dump_plant_object())
        end
    end 
    plant_data.worker_id = self.__worker_id
    plant_data.timestamp = self.__timestamp
    plant_data.cloud_count = self.__cloud_count
    return plant_data
end

function PlantRuler:get_worker_id()
    return self.__worker_id
end

function PlantRuler:serialize_plant_data()
    local plant_data = self.dump_plant_data(self)
    return packer.encode(plant_data)
end

function PlantRuler:get_next_refresh_timestamp()
    return self.__timestamp
end

function PlantRuler:get_cloud_count()
    return self.__cloud_count
end

function PlantRuler:check_can_add_worker()
    return self.__worker_id <= 0
end

function PlantRuler:employment_worker_object(worker_id,timestamp)
    if not self:check_can_add_worker() then 
        LOG_ERROR("worker_id:%d timestamp:%s error:%s",worker_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_add_worker))
        return GAME_ERROR.cant_add_worker 
    end
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    self.__worker_id = worker_id
    worker_object:set_build_id(1001001)
    self:refresh_harvest_time(timestamp)
    return 0
end

function PlantRuler:get_off_work(timestamp)
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if not worker_object then
        LOG_ERROR("timestamp:%s error:%s",get_epoch_time(timestamp),errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist
    end
    local accelerate = worker_object:get_accelerate() * 0.01 + 1
    for k,plant_object in pairs(self.__plant_objects) do
        if plant_object:get_states() == plant_const.planting then
            local start_time = plant_object:get_plant_time()
            local harvest_time = plant_object:get_harvest_time()
            local finish_time = plant_object:get_finish_time()
            local remain_time = harvest_time - timestamp 
            if remain_time > 0 then
                harvest_time = finish_time + start_time - math.ceil((timestamp - start_time) * (accelerate - 1))
                plant_object:set_harvest_time(harvest_time)
            end
        end
    end
    self.__worker_id = 0
    worker_object:get_off_work()
    return 0
end

function PlantRuler:refresh_harvest_time(timestamp)
    local worker_id = self:get_worker_id()
    local employment_ruler = self.__role_object:get_employment_ruler()
	local worker_object = employment_ruler:get_worker_object(worker_id)
	local accelerate = 1 
	if worker_object then
    	accelerate = worker_object:get_accelerate() * 0.01 + 1
	end
    for k,plant_object in pairs(self.__plant_objects) do
        if plant_object:get_states() == plant_const.planting then
            local harvest_time = plant_object:get_harvest_time()
            local remain_time = harvest_time - timestamp 
            harvest_time = timestamp + math.ceil(remain_time / accelerate)
            plant_object:set_harvest_time(harvest_time)

        end
    end
end

function PlantRuler:add_plant_object(build_id)
    local plant_object = PlantObject.new(build_id)
    self.__plant_objects[build_id] = plant_object
end

function PlantRuler:get_plant_object(build_id)
    return self.__plant_objects[build_id]
end

function PlantRuler:get_plant_entry(plant_index)
    return self.__plant_manager:get_plant_entry(plant_index)
end

function PlantRuler:planting_products(build_id,plant_index,timestamp)
    local plant_object = self.get_plant_object(self,build_id)
    if not plant_object then
        LOG_ERROR("build_id : %d plant_index : %d timestamp : %s error : %s",build_id,plant_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.building_not_exist))
        return GAME_ERROR.building_not_exist 
    end
    if not plant_object:check_can_plant() then
        LOG_ERROR("build_id : %d plant_index : %d timestamp : %s error : %s",build_id,plant_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_operate_building))
        return GAME_ERROR.cant_operate_building
    end
    local plant_entry = self.get_plant_entry(self,plant_index)
    if not plant_entry then
        LOG_ERROR("build_id : %d plant_index : %d timestamp : %s error : %s",build_id,plant_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_operate_building))
        return GAME_ERROR.cant_operate_building 
    end
    local consume_money = plant_entry:get_consume_money()
    if not self.__role_object:check_enough_gold(consume_money) then
        LOG_ERROR("build_id : %d plant_index : %d timestamp : %s error : %s",build_id,plant_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.gold_not_enough))
        return GAME_ERROR.gold_not_enough
    end
    local unlock_level = plant_entry:get_unlock_level()
    local role_level = self.__role_object:get_level()
    if self.__role_object:get_level() < unlock_level then
        LOG_ERROR("build_id : %d plant_index : %d timestamp : %s error : %s",build_id,plant_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.operate_not_unlock))
        return GAME_ERROR.operate_not_unlock
    end
    self.__role_object:consume_gold(consume_money,CONSUME_CODE.plant) 
    plant_object:start_plant_crop(timestamp,plant_entry)
    local worker_id = self:get_worker_id()
    local employment_ruler = self.__role_object:get_employment_ruler()
    local worker_object = employment_ruler:get_worker_object(worker_id)
    local accelerate = 1 
    if worker_object then 
        accelerate = worker_object:get_accelerate() * 0.01 + 1
    end
	local finish_time = plant_object:get_finish_time()
	local harvest_time = timestamp + math.floor(finish_time / accelerate)
    plant_object:set_harvest_time(harvest_time)
    self.__role_object:publish("plant","plant",self.__role_object:get_account_id(),build_id,plant_index,harvest_time)
    self.__role_object:get_daily_ruler():plant_crop()
    return 0
end

function PlantRuler:harvest_products(build_id,timestamp)
    local plant_object = self.get_plant_object(self,build_id)
    if not plant_object then
        LOG_ERROR("build_id : %d  timestamp : %s error : %s",build_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.building_not_exist))
        return GAME_ERROR.building_not_exist
    end
    if not plant_object:check_can_harvest(timestamp) then
        LOG_ERROR("build_id : %d timestamp : %s error : %s",build_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_harvest))
        return GAME_ERROR.cant_harvest 
    end
    if not self.__role_object:get_item_ruler():check_item_capacity(1) then
        LOG_ERROR("item_count:%d err:%s",1,errmsg(GAME_ERROR.item_capacity_not_enough))
        return GAME_ERROR.item_capacity_not_enough
    end
    local plant_exp = plant_object:get_plant_entry():get_plant_exp()
    local item_index = plant_object:get_plant_entry():get_product_item()
    plant_object:harvest_products(timestamp)
    local item_count = 1
    self.__role_object:add_exp(plant_exp,SOURCE_CODE.harvest)
    self.__role_object:add_item(item_index,item_count,SOURCE_CODE.harvest)
    self.__role_object:get_achievement_ruler():harvest_farmland(item_count)
    self.__role_object:get_achievement_ruler():limit_harvest_farmland(timestamp,1)
    self.__role_object:get_daily_ruler():plant_harvest()
    self.__role_object:publish("plant","harvest",self.__role_object:get_account_id(),build_id)
    return 0
end

function PlantRuler:promote_plant(build_id,cash_count,timestamp)
    local plant_object = self.get_plant_object(self,build_id)
    if not plant_object then
        LOG_ERROR("build_id : %d  timestamp : %s error : %s",build_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.building_not_exist))
        return GAME_ERROR.building_not_exist
    end
    if not plant_object:check_can_promote(timestamp) then
        LOG_ERROR("build_id : %d timestamp : %s error : %s",build_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_operate_building))
        return GAME_ERROR.cant_operate_building 
    end
    local remain_time = plant_object:get_remain_time(timestamp)
    local cost_cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if cost_cash ~= cash_count then
        LOG_ERROR("cost_count : %d cash_count : %d error : %s",cost_cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_cash(cost_cash) then
        LOG_ERROR("cost_count : %d error : %s",cost_cash ,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.cash_not_enough 
    end
    self.__role_object:consume_cash(cost_cash,CONSUME_CODE.promote)
    plant_object:set_status(plant_const.promote)
    self.__role_object:publish("plant","promote",self.__role_object:get_account_id(),build_id)
    return 0
end

function PlantRuler:create_cloud(timestamp)
    if self.__timestamp > timestamp then
        LOG_ERROR("timestamp : %s error : %s",get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_create_cloud))
        return GAME_ERROR.cant_create_cloud 
    end
    if self.__cloud_count >= MAX_CLOUD then
        LOG_ERROR("timestamp : %s error : %s",get_epoch_time(timestamp),errmsg(GAME_ERROR.cloud_queue_full))
        return GAME_ERROR.cloud_queue_full
    end
    local interval = utils.get_random_int(5,10)
    local next_timestamp = timestamp + interval * 60
    self.__timestamp = next_timestamp
    self.__cloud_count = self.__cloud_count + 1
    return 0
end

function PlantRuler:promote_plant_by_cloud(build_id,timestamp)
    if self.__cloud_count < 1 then
        LOG_ERROR("timestamp : %s error : %s",get_epoch_time(timestamp),errmsg(GAME_ERROR.cloud_not_enough))
        return GAME_ERROR.cloud_not_enough
    end
    self.__cloud_count = self.__cloud_count - 1
    self:create_cloud(timestamp)
    local plant_object = self.get_plant_object(self,build_id)
    if not plant_object then
        return 0
    end
    if not plant_object:check_can_promote(timestamp) then
        return 0
    end
    plant_object:set_status(plant_const.promote)
    self.__role_object:publish("plant","promote",self.__role_object:get_account_id(),build_id)
    return 0
end

function PlantRuler:watering(account_id,build_id,timestamp)
    local plant_object = self.get_plant_object(self,build_id)
    if not plant_object then
        LOG_ERROR("build_id:%d err:%s",build_id,errmsg(GAME_ERROR.building_not_exist))
        return GAME_ERROR.building_not_exist
    end
    if plant_object:check_can_harvest(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_watering))
        return GAME_ERROR.cant_watering
    end
    if not plant_object:check_can_watering() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_watering))
        return GAME_ERROR.cant_watering
    end
    local harvest_time = plant_object:get_harvest_time()
    harvest_time = harvest_time - WATERTIME
    plant_object:set_harvest_time(harvest_time)
    plant_object:set_role_id(account_id)
    self.__role_object:send_request("update_watering",{build_id=build_id,account_id=account_id})
    self.__role_object:publish("plant","watering",self.__role_object:get_account_id(),account_id,build_id)
    self.__role_object:add_friendly(FRIENDLY,SOURCE_CODE.behelped)
    return 0,FRIENDLY
end

return PlantRuler