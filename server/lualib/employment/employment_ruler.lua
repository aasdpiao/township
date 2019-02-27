local class = require "class"
local EmploymentManager = require "employment.employment_manager"
local EmploymentDispatcher = require "employment.employment_dispatcher"
local packer = require "db.packer"
local WorkerObject = require "employment.worker_object"
local utils = require "utils"
local syslog = require "syslog"

local EmploymentRuler = class()

local MAX_SLOT_COUNT = 20
local DEFAULT_SLOT_COUNT = 200

function EmploymentRuler:ctor(role_object)
    self.__role_object = role_object

    self.__upper_count = 0

    self.__free_timestamp = 0
    self.__cash_timestamp = 0

    self.__free_times = 0
end

function EmploymentRuler:init()
    self.__employment_manager = EmploymentManager.new(self.__role_object)
    self.__employment_manager:init()
    
    self.__employment_dispatcher = EmploymentDispatcher.new(self.__role_object)
    self.__employment_dispatcher:init()

    self.__worker_seed = 1000           --worker_id
    self.__worker_objects = {}
end

function EmploymentRuler:get_employment_manager()
    return self.__employment_manager
end

function EmploymentRuler:get_worker_id()
    self.__worker_seed = self.__worker_seed + 1
    return self.__worker_seed
end

function EmploymentRuler:load_employment_data(employment_data)
    if not employment_data then return end
    local code = packer.decode(employment_data)
    local worker_objects = code.worker_objects or {}
    local worker_seed = code.worker_seed or 1000
    local upper_count = code.upper_count or 0
    local free_timestamp = code.free_timestamp or 0
    local cash_timestamp = code.cash_timestamp or 0
    local free_times = code.free_times or 0
    self.__worker_seed = worker_seed
    self.__upper_count = upper_count
    self.__cash_timestamp = cash_timestamp
    self.__free_timestamp = free_timestamp
    self.__free_times = free_times
    for k,worker_data in pairs(worker_objects) do
        local worker_id = worker_data.worker_id
        local worker_object = WorkerObject.new(self.__role_object,worker_id)
        worker_object:load_worker_object(worker_data)
        self:add_worker_object(worker_object)
    end
end

function EmploymentRuler:restore_worker_object(worker_data)
    local worker_id = worker_data.worker_id
    local worker_object = WorkerObject.new(self.__role_object,worker_id)
    worker_object:load_worker_object(worker_data)
    self:add_worker_object(worker_object)
end

function EmploymentRuler:dump_employment_data()
    local employment_data = {}
    employment_data.worker_seed = self.__worker_seed
    employment_data.upper_count = self.__upper_count
    employment_data.free_timestamp = self.__free_timestamp
    employment_data.cash_timestamp = self.__cash_timestamp
    employment_data.free_times = self.__free_times
    employment_data.worker_objects = {}
    for k,worker_object in pairs(self.__worker_objects) do
        table.insert( employment_data.worker_objects, worker_object:dump_worker_object() )
    end
    return employment_data
end

function EmploymentRuler:serialize_employment_data()
    local employment_data = self.dump_employment_data(self)
    return packer.encode(employment_data)
end

function EmploymentRuler:get_max_count()
    return DEFAULT_SLOT_COUNT + 5 * self.__upper_count
end

function EmploymentRuler:check_can_add_upper(slot_index)
    if self.__upper_count + 1 ~= slot_index then return false end
    return self.__upper_count < MAX_SLOT_COUNT
end

function EmploymentRuler:get_add_upper_cash(slot_index)
    return (math.ceil(slot_index/5.0) * 5)
end

function EmploymentRuler:add_upper_count()
    self.__upper_count = self.__upper_count + 1
end

function EmploymentRuler:get_worker_object(worker_id)
    return self.__worker_objects[worker_id]
end

function EmploymentRuler:add_worker_object(worker_object)
    local worker_id = worker_object:get_worker_id()
    self.__worker_objects[worker_id] = worker_object
end

function EmploymentRuler:remove_worker_object(worker_id)
    self.__worker_objects[worker_id] = nil
end

function EmploymentRuler:update_new_day(timestamp)
    local free_timestamp = self.__free_timestamp
    local interval_time = utils.get_interval_timestamp(free_timestamp)
    if timestamp >= interval_time then
        self.__free_times = 0
        self.__free_timestamp = 0
    end
end

function EmploymentRuler:check_free_worker(employ_index,timestamp)
    self:update_new_day(timestamp)
    local employ_entry = self.__employment_manager:get_employ_entry(employ_index)
    local free_interval = employ_entry:get_free_interval()
    local free_times = employ_entry:get_free_times()
    if employ_index == 1001 then  --普通雇佣
        if self.__free_timestamp + free_interval > timestamp then return false end
        return self.__free_times < free_times 
    else
        return self.__cash_timestamp + free_interval <= timestamp
    end
end

function EmploymentRuler:gen_free_worker(employ_index,timestamp)
    if employ_index == 1001 then
        self.__free_times = self.__free_times + 1
        self.__free_timestamp = timestamp
        return self:gen_worker_object(employ_index)
    elseif employ_index == 2001 then
        self.__cash_timestamp = timestamp
        return self:gen_worker_object(employ_index)
    end
end


function EmploymentRuler:gen_worker_object(employ_index)
    local worker_id = self:get_worker_id()
    local worker_object = self.__employment_manager:gen_worker_object(employ_index,worker_id)
    return worker_object
end

function EmploymentRuler:gen_ten_worker_object(employ_index)
    local worker_objects = {}
    local check_ten = false
    for i=1,10 do
        local worker_id = self:get_worker_id()
        local worker_object = self.__employment_manager:gen_worker_object(employ_index,worker_id)
        table.insert( worker_objects, worker_object)
        if worker_object:get_worker_state() >= 4 then check_ten = true end
    end
    if not check_ten then 
        local random_seed = utils.get_random_int(1,10)
        local worker_object = worker_objects[random_seed]
        worker_object:set_worker_state(4)
        worker_object:set_worker_level(16)
    end
    return worker_objects
end

function EmploymentRuler:calc_worker_exp(worker_objects)
    local total_exp = 0
    for i,worker_data in ipairs(worker_objects) do
        local worker_id = worker_data.worker_id
        local worker_object = self:get_worker_object(worker_id)
        local level = worker_object:get_worker_level()
        local levelup_entry = self.__employment_manager:get_levelup_entry(level)
        local exp = levelup_entry:get_worker_exp()
        total_exp = total_exp + exp 
        self:remove_worker_object(worker_id)
    end
    return total_exp
end

function EmploymentRuler:debug_info()
    local employment_info = ""
    for worker_id,worker_object in pairs(self.__worker_objects) do
        employment_info = employment_info..worker_object:debug_info().."\n"
    end
    employment_info = employment_info.."upper_count "..self.__upper_count.."\n"
    employment_info = employment_info.."free_times "..self.__free_times.."\n"
    employment_info = employment_info.."free_timestamp "..self.__free_timestamp.."\n"
    employment_info = employment_info.."cash_timestamp "..self.__cash_timestamp.."\n"
    return employment_info
end


return EmploymentRuler