local class = require "class"
local TrainsManager = require "trains.trains_manager"
local TrainsDispatcher = require "trains.trains_dispatcher"
local TrainsObject = require "trains.trains_object"
local packer = require "db.packer"
local trains_const = require "trains.trains_const"
local print_r = require "print_r"
local syslog = require "syslog"

local TrainsRuler = class()

function TrainsRuler:ctor(role_object)
    self.__role_object = role_object
    self.__station_status = 0           --0未解锁，1已解锁
    self.__worker_id = 0                --雇佣id
    self.__trains_objects = {}
end

function TrainsRuler:init()
    self.__trains_manager = TrainsManager.new()
    self.__trains_manager:init()

    self.__trains_dispatcher = TrainsDispatcher.new(self.__role_object)
    self.__trains_dispatcher:init()

    local trains_entrys = self.__trains_manager:get_trains_entrys()
    for k,trains_entry in pairs(trains_entrys) do
        local trains_index = trains_entry:get_trains_index()
        local trains_object = TrainsObject.new(self.__role_object,trains_entry)
        self.__trains_objects[trains_index] = trains_object
    end
end

function TrainsRuler:get_order_entry(order_index)
    return self.__trains_manager:get_order_entry(order_index)
end

function TrainsRuler:get_reward_entry(reward_index)
    return self.__trains_manager:get_reward_entry(reward_index)
end

function TrainsRuler:get_terminal_entry(terminal_index)
    return self.__trains_manager:get_terminal_entry(terminal_index)
end

function TrainsRuler:get_trains_entry(trains_index)
    return self.__trains_manager:get_trains_entry(trains_index)
end

function TrainsRuler:get_trains_object(trains_index)
    return self.__trains_objects[trains_index]
end

function TrainsRuler:load_trains_data(trains_data)
    if not trains_data then return end
    local code = packer.decode(trains_data)
    local trains_objects = code.trains_objects
    local station_status = code.station_status
    local worker_id = code.worker_id
    if not station_status then return end
    self.__station_status = station_status
    if not trains_objects then return end
    for k,v in pairs(trains_objects) do
        local trains_index = v.trains_index
        local trains_object = self.get_trains_object(self,trains_index)
        trains_object:load_trains_object(v)
    end
    if not worker_id then return end
    self.__worker_id = worker_id
end

function TrainsRuler:dump_trains_data()
    local trains_data = {}
    trains_data.station_status = self.__station_status
    trains_data.worker_id = self.__worker_id
    trains_data.trains_objects = {}
    for k,trains_object in pairs(self.__trains_objects) do
        if trains_object:get_trains_unlock() == trains_const.unlock then
            table.insert( trains_data.trains_objects, trains_object:dump_trains_object())
        end
    end
    return trains_data
end

function TrainsRuler:serialize_trains_data()
    local trains_data = self.dump_trains_data(self)
    return packer.encode(trains_data)
end

function TrainsRuler:check_can_unlock_station()
    local build_id = 5001001
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
    local unlock_level = unlock_entry:get_level()
    if not self.__role_object:check_level(unlock_level) then return false end
    if self.__station_status == 1 then return false end
    return true
end

function TrainsRuler:unlock_station()
    self.__station_status = 1 
end

function TrainsRuler:check_can_add_worker(timestamp)
    return self.__worker_id <= 0
end

function TrainsRuler:employment_worker_object(worker_id,timestamp)
    if not self:check_can_add_worker(timestamp) then
        LOG_ERROR("worker_id:%d timestamp:%s error:%s",worker_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_add_worker))
        return GAME_ERROR.cant_add_worker
    end
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    self.__worker_id = worker_id
    worker_object:set_build_id(5001001)
    self:refresh_wait_time(true,timestamp)
    return 0
end

function TrainsRuler:get_off_work(timestamp)
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if not worker_object then
        LOG_ERROR("timestamp:%s error:%s",get_epoch_time(timestamp),errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    self:refresh_wait_time(false,timestamp)
    self.__worker_id = 0
    worker_object:get_off_work()
    return 0
end

function TrainsRuler:refresh_wait_time(employ,timestamp)
    for i,v in pairs(self.__trains_objects) do
        v:refresh_wait_time(employ,timestamp)
    end
end

function TrainsRuler:get_worker_object()
    return self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
end

function TrainsRuler:unlock_trains(trains_index)
    local trains_object = self:get_trains_object(trains_index)
    assert(trains_object,"trains: "..trains_index.." is nil")
    if not trains_object:check_can_unlock() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_unlock))
        return GAME_ERROR.cant_unlock
    end
    local money = trains_object:get_unlock_money()
    self.__role_object:consume_gold(money,CONSUME_CODE.unlock)
    trains_object:unlock_trains_object()
    if trains_index == 1001 then
        trains_object:first_trains_object()
    else
        trains_object:generate_trains_object()
    end
    return 0
end

function TrainsRuler:get_trains_orders()
    return self.__trains_manager:get_trains_orders(self.__role_object)
end

function TrainsRuler:get_trains_rewards(count)
    return self.__trains_manager:get_trains_rewards(self.__role_object,count)
end

function TrainsRuler:get_terminal_index()
    return self.__trains_manager:get_terminal_index(self.__role_object)
end

function TrainsRuler:finish_trains_help(account_id,trains_index,order_object)
    local trains_object = self:get_trains_object(trains_index)
    if not trains_object then 
        LOG_ERROR("trains_index:%d,err:%s",trains_index,errmsg(GAME_ERROR.trains_not_exist))
        return GAME_ERROR.trains_not_exist
    end
    return trains_object:finish_trains_help(account_id,order_object)
end

function TrainsRuler:debug_info()
    local trains_info = ""
    trains_info = trains_info.."station_status:"..self.__station_status.."\n"
    for k,trains_object in pairs(self.__trains_objects) do
        trains_info = trains_info..trains_object:debug_info().."\n"
    end
    return trains_info
end

function TrainsRuler:confirm_friends_help(trains_index,timestamp,order_index)
    local trains_object = self:get_trains_object(trains_index)
    if not trains_object then 
        LOG_ERROR("trains_index:%d,err:%s",trains_index,errmsg(GAME_ERROR.trains_not_exist))
        return GAME_ERROR.trains_not_exist
    end
    local result = trains_object:confirm_friends_help(order_index)
    trains_object:flush_trains_status(timestamp)
    return result
end

return TrainsRuler