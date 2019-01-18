local class = require "class"
local skynet = require "skynet"
local plant_const = require "plant.plant_const"
local cjson = require "cjson"
local PlantObject = class()


function PlantObject:ctor(build_id)
    self.__build_id = build_id
    self.__timestamp = 0
    self.__plant_index = 0
    self.__plant_entry = nil
    self.__harvest_time = 0
    self.__status = plant_const.empty
    self.__role_id = 0
end

function PlantObject:get_plant_entry()
    return self.__plant_entry
end

function PlantObject:dump_plant_object()
    local plant_object = {}
    plant_object.build_id = self.__build_id
    plant_object.timestamp = self.__timestamp
    plant_object.plant_index = self.__plant_index
    plant_object.status = self.__status
    plant_object.harvest_time = self.__harvest_time
    plant_object.role_id = self.__role_id
    return plant_object
end

function PlantObject:check_can_plant()
    return self.__status == plant_const.empty
end

function PlantObject:set_harvest_time(harvest_time)
    self.__harvest_time = harvest_time
end

function PlantObject:get_harvest_time()
    return self.__harvest_time
end

function PlantObject:get_finish_time()
    return self.__plant_entry:get_finish_time()
end

function PlantObject:get_plant_time()
    return self.__timestamp
end

function PlantObject:check_can_promote(timestamp)
    if self.__plant_index <= 0 then return false end
    if self.__status ~= plant_const.planting then return false end
    return timestamp < self.__harvest_time
end

function PlantObject:check_can_harvest(timestamp)
    if self.__plant_index <= 0 then return false end
    if self.__status == plant_const.promote then return true end
    return timestamp >= self.__harvest_time
end

function PlantObject:set_status(status)
    self.__status = status
end

function PlantObject:set_role_id(role_id)
    self.__role_id = role_id
end

function PlantObject:check_can_watering()
    return self.__role_id == 0
end

function PlantObject:get_remain_time(timestamp)
    if self.__status ~= plant_const.planting then return 0 end
    return self.__harvest_time - timestamp
end

function PlantObject:start_plant_crop(time_stamp,plant_entry)
    self.__status = plant_const.planting
    self.__timestamp = time_stamp
    self.__plant_entry = plant_entry
    self.__plant_index = plant_entry:get_plant_index()
    self.__harvest_time = time_stamp + self:get_finish_time()
end

function PlantObject:harvest_products(timestamp)
    self.__status = plant_const.empty
    self.__timestamp = 0
    self.__harvest_time = 0
    self.__plant_entry = nil
    self.__plant_index = 0
    self.__role_id = 0
end

function PlantObject:get_states()
    return self.__status
end

return PlantObject