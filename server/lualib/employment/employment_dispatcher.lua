local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local EmploymentDispatcher = class()

function EmploymentDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function EmploymentDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function EmploymentDispatcher:init()
    self:register_c2s_callback("employment_worker",self.dispatcher_employment_worker)
    self:register_c2s_callback("employment_ten_worker",self.dispatcher_employment_ten_worker)
    self:register_c2s_callback("worker_level_up",self.dispatcher_worker_level_up)
    self:register_c2s_callback("worker_upgrade",self.dispatcher_worker_upgrade)
    self:register_c2s_callback("free_employment",self.dispatcher_free_employment)
    self:register_c2s_callback("add_upper_count",self.dispatcher_add_upper_count)
end

function EmploymentDispatcher.dispatcher_employment_worker(role_object,msg_data)
    local level = role_object:get_level()
    if level < 18 then
        LOG_ERROR("level:%d err:%s",level,errmsg(GAME_ERROR.level_not_enough))
        return {result = GAME_ERROR.level_not_enough} 
    end
    local employ_index = msg_data.employ_index
    if not role_object:check_enough_cash(20) then
        LOG_ERROR("cash:%d err:%s",20,errmsg(GAME_ERROR.cash_not_enough))
        return {result = GAME_ERROR.cash_not_enough} 
    end
    role_object:consume_cash(20,CONSUME_CODE.employment_worker)
    local employment_ruler = role_object:get_employment_ruler()
    local worker_object = employment_ruler:gen_worker_object(employ_index)
    employment_ruler:add_worker_object(worker_object)
    return {result = 0, worker_object = worker_object:dump_worker_object()}
end

function EmploymentDispatcher.dispatcher_employment_ten_worker(role_object,msg_data)
    local level = role_object:get_level()
    if level < 18 then
        LOG_ERROR("level:%d err:%s",level,errmsg(GAME_ERROR.level_not_enough))
        return {result = GAME_ERROR.level_not_enough} 
    end
    if not role_object:check_enough_cash(200) then
        LOG_ERROR("cash:%d err:%s",200,errmsg(GAME_ERROR.cash_not_enough))
        return {result = GAME_ERROR.cash_not_enough} 
    end
    role_object:consume_cash(200,CONSUME_CODE.employment_worker)
    local employ_index = msg_data.employ_index
    local employment_ruler = role_object:get_employment_ruler()
    local worker_objects = employment_ruler:gen_ten_worker_object(employ_index)
    local worker_data = {}
    for i,worker_object in ipairs(worker_objects) do
        employment_ruler:add_worker_object(worker_object)
        table.insert( worker_data, worker_object:dump_worker_object())
    end
    return {result = 0,worker_objects = worker_data}
end

function EmploymentDispatcher.dispatcher_worker_level_up(role_object,msg_data)
    local worker_id = msg_data.worker_id
    local worker_objects = msg_data.worker_objects
    local employment_ruler = role_object:get_employment_ruler()
    local worker_object = employment_ruler:get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    local total_exp = employment_ruler:calc_worker_exp(worker_objects)
    worker_object:add_worker_exp(total_exp)
    return {result = 0}
end

function EmploymentDispatcher.dispatcher_worker_upgrade(role_object,msg_data)
    local worker_id = msg_data.worker_id
    local topaz = msg_data.topaz
    local emerald = msg_data.emerald
    local ruby = msg_data.ruby
    local amethyst = msg_data.amethyst
    local employment_ruler = role_object:get_employment_ruler()
    local employment_manager = employment_ruler:get_employment_manager()
    local worker_object = employment_ruler:get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    local state = worker_object:get_worker_state()
    local profession = worker_object:get_worker_profession()
    local worker_state = employment_manager:get_worker_state(profession,state)

    local state_topaz = worker_state:get_topaz()
    local state_emerald = worker_state:get_emerald()
    local state_ruby = worker_state:get_ruby()
    local state_amethyst = worker_state:get_amethyst()

    if not topaz == state_topaz then
        LOG_ERROR("topaz:%d state_topaz:%d err:%s",topaz,state_topaz,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not emerald == state_emerald then
        LOG_ERROR("emerald:%d state_emerald:%d err:%s",emerald,state_emerald,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not ruby == state_ruby then
        LOG_ERROR("ruby:%d state_ruby:%d err:%s",ruby,state_ruby,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not amethyst == state_amethyst then
        LOG_ERROR("amethyst:%d state_amethyst:%d err:%s",amethyst,state_amethyst,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end

    if not role_object:check_enough_topaz(topaz) then
        LOG_ERROR("topaz:%d err:%s",topaz,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.topaz_not_enough
    end
    if not role_object:check_enough_emerald(emerald) then
        LOG_ERROR("emerald:%d err:%s",emerald,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.emerald_not_enough
    end
    if not role_object:check_enough_ruby(ruby) then
        LOG_ERROR("ruby:%d err:%s",ruby,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.ruby_not_enough
    end
    if not role_object:check_enough_amethyst(amethyst) then
        LOG_ERROR("amethyst:%d err:%s",amethyst,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.amethyst_not_enough
    end
    if not worker_object:check_can_upgrade() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_upgrade))
        return GAME_ERROR.cant_upgrade
    end
    role_object:consume_topaz(topaz,CONSUME_CODE.worker_upgrade)
    role_object:consume_emerald(emerald,CONSUME_CODE.worker_upgrade)
    role_object:consume_ruby(ruby,CONSUME_CODE.worker_upgrade)
    role_object:consume_amethyst(amethyst,CONSUME_CODE.worker_upgrade)
    worker_object:upgrade_worker()
    return {reulst = 0}
end

function EmploymentDispatcher.dispatcher_free_employment(role_object,msg_data)
    local level = role_object:get_level()
    if level < 18 then 
        LOG_ERROR("level:%d err:%s",level,errmsg(GAME_ERROR.level_not_enough))
        return {result = GAME_ERROR.level_not_enough}
    end
    local timestamp = msg_data.timestamp
    local employ_index = msg_data.employ_index
    local employment_ruler = role_object:get_employment_ruler()
    if not employment_ruler:check_free_worker(employ_index,timestamp) then
        LOG_ERROR("employ_index:%d timestamp:%d err:%s",employ_index,timestamp,errmsg(GAME_ERROR.cant_employ))
        return {result = GAME_ERROR.cant_employ} 
    end 
    local worker_object = employment_ruler:gen_free_worker(employ_index,timestamp)
    employment_ruler:add_worker_object(worker_object)
    return {result = 0, worker_object = worker_object:dump_worker_object()}
end

function EmploymentDispatcher.dispatcher_add_upper_count(role_object,msg_data)
    local slot_index = msg_data.slot_index
    local cash_count = msg_data.cash_count
    local employment_ruler = role_object:get_employment_ruler()
    if not employment_ruler:check_can_add_upper(slot_index) then
        LOG_ERROR("slot_index:%d err:%s",slot_index,errmsg(GAME_ERROR.cant_add_slot))
        return {result = GAME_ERROR.cant_add_slot} 
    end
    local cash = employment_ruler:get_add_upper_cash()
    if cash ~= cash_count then
        LOG_ERROR("cash:%d cash_count:%d err:%s",cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return {result = GAME_ERROR.number_not_match} 
    end
    if not role_object:check_enough_cash(cash) then
        LOG_ERROR("cash_count:%d err:%s",cash,errmsg(GAME_ERROR.cash_not_enough))
        return {result = GAME_ERROR.cash_not_enough} 
    end
    role_object:consume_cash(cash,CONSUME_CODE.add_upper)
    employment_ruler:add_upper_count()
    return {result = 0}
end

return EmploymentDispatcher