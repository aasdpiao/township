local class = require "class"
local AchievementManager = require "achievement.achievement_manager"
local AchievementObject = require "achievement.achievement_object"
local AchievementDispatcher = require "achievement.achievement_dispatcher"
local achievement_const = require "achievement.achievement_const"
local packer = require "db.packer"
local syslog = require "syslog"

local AchievementRuler = class()

function AchievementRuler:ctor(role_object)
    self.__role_object = role_object

    self.__worker_id = 0
    self.__achievement_objects = {}
    self.__finish_helicopter = 0
    self.__finish_trains = 0
    self.__finish_flight = 0
    self.__finish_ship = 0
    self.__finish_product = 0
end

function AchievementRuler:init()
    self.__achievement_manager = AchievementManager.new(self.__role_object)
    self.__achievement_manager:init()

    self.__achievement_dispatcher = AchievementDispatcher.new(self.__role_object)
    self.__achievement_dispatcher:init()
end

function AchievementRuler:load_achievement_data(achievement_data)
    if not achievement_data then return end
    local code = packer.decode(achievement_data) or {}
    local achievement_objects = code.achievement_objects or {}
    local worker_id = code.worker_id or 0
    local finish_helicopter = code.finish_helicopter or 0
    local finish_trains = code.finish_trains or 0
    local finish_flight = code.finish_flight or 0
    local finish_ship = code.finish_ship or 0
    local finish_product = code.finish_product or 0
    self.__worker_id = worker_id
    self.__finish_helicopter = finish_helicopter
    self.__finish_trains = finish_trains
    self.__finish_flight = finish_flight
    self.__finish_ship = finish_ship
    self.__finish_product = finish_product
    self:load_achievement_objects(achievement_objects)
end

function AchievementRuler:load_achievement_objects(achievement_objects)
    for i,v in ipairs(achievement_objects) do
        local achievement_type = v.achievement_type
        local achievement_object = self:get_achievement_object(achievement_type)
        achievement_object:load_achievement_object(v)
    end
end

function AchievementRuler:dump_achievement_data()
    local achievement_data = {}
    achievement_data.worker_id = self.__worker_id
    achievement_data.achievement_objects = self:dump_achievement_objects()
    achievement_data.finish_helicopter = self.__finish_helicopter
    achievement_data.finish_trains = self.__finish_trains
    achievement_data.finish_flight = self.__finish_flight
    achievement_data.finish_ship = self.__finish_ship
    achievement_data.finish_product = self.__finish_product
    return achievement_data
end

function AchievementRuler:dump_achievement_objects()
    local achievement_objects = {}
    for k,v in pairs(self.__achievement_objects) do
        table.insert( achievement_objects, v:dump_achievement_object())
    end
    return achievement_objects
end

function AchievementRuler:serialize_achievement_data()
    local achievement_data = self.dump_achievement_data(self)
    return packer.encode(achievement_data)
end

function AchievementRuler:check_can_add_worker(timestamp)
    return self.__worker_id <= 0
end

function AchievementRuler:employment_worker_object(worker_id,timestamp)
    if not self:check_can_add_worker(timestamp) then
        LOG_ERROR("worker_id:%d timestamp:%s error:%s",worker_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_add_worker))
        return GAME_ERROR.cant_add_worker
    end
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    self.__worker_id = worker_id
    worker_object:set_build_id(5006001)
    return 0
end

function AchievementRuler:get_off_work(timestamp)
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if not worker_object then
        LOG_ERROR("timestamp:%s error:%s",get_epoch_time(timestamp),errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    self.__worker_id = 0
    worker_object:get_off_work()
    return 0
end

function AchievementRuler:get_achievement_entry(achievement_type)
    return self.__achievement_manager:get_achievement_entry(achievement_type)
end

function AchievementRuler:get_achievement_object(achievement_type)
    if not self.__achievement_objects[achievement_type] then
        local achievement_entry = self:get_achievement_entry(achievement_type)
        assert(achievement_entry,"achievement_type is nil :"..achievement_type)
        local achievement_object = AchievementObject.new(self.__role_object,achievement_entry)
        self.__achievement_objects[achievement_type] = achievement_object
        return achievement_object
    end
    return self.__achievement_objects[achievement_type]
end

function AchievementRuler:finish_achievement_object(achievement_type,stage)
    self.__role_object:send_request("finish_achievement",{
        achievement_type = achievement_type,
        status = stage,
    })
end

function AchievementRuler:receive_achievement(achievement_type,status)
    local achievement_object = self:get_achievement_object(achievement_type)
    local achievement_entry = self:get_achievement_entry(achievement_type) 
    local achievement_stage = achievement_entry:get_achievement_stage(status)
    local exp = achievement_stage:get_exp()
    local cash = achievement_stage:get_cash()
    self.__role_object:add_cash(cash,SOURCE_CODE.achieve)
    self.__role_object:add_exp(exp,SOURCE_CODE.achieve)
    achievement_object:receive_achievement(status)
    return 0,cash,exp
end

function AchievementRuler:check_can_receive(achievement_type,stage)
    local achievement_object = self:get_achievement_object(achievement_type)
    return achievement_object:check_can_receive(stage)
end

function AchievementRuler:finish_helicopter_order()
    local achievement_object = self:get_achievement_object(achievement_const.helicopter_order)
    achievement_object:add_finish_times()
end

function AchievementRuler:refresh_population_upper(population)
    local achievement_object = self:get_achievement_object(achievement_const.population_upper)
    achievement_object:refresh_finish_times(population)
end

function AchievementRuler:finish_build_factory()
    local achievement_object = self:get_achievement_object(achievement_const.build_factory)
    achievement_object:add_finish_times()
end

function AchievementRuler:finish_trains_order()
    local achievement_object = self:get_achievement_object(achievement_const.trains_order)
    achievement_object:add_finish_times()
end

function AchievementRuler:earn_gold_count(count)
    local achievement_object = self:get_achievement_object(achievement_const.earn_money)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:decoration_money(count)
    local achievement_object = self:get_achievement_object(achievement_const.decoration_money)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:factory_product(count)
    local achievement_object = self:get_achievement_object(achievement_const.factory_product)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:build_house()
    local achievement_object = self:get_achievement_object(achievement_const.build_house)
    achievement_object:add_finish_times()
end

function AchievementRuler:build_organization()
    local achievement_object = self:get_achievement_object(achievement_const.build_organization)
    achievement_object:add_finish_times()
end

function AchievementRuler:cost_city_money(count)
    local achievement_object = self:get_achievement_object(achievement_const.city_money)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:harvest_milk(count)
    local achievement_object = self:get_achievement_object(achievement_const.harvest_milk)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:harvest_egg(count)
    local achievement_object = self:get_achievement_object(achievement_const.harvest_egg)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:harvest_wool(count)
    local achievement_object = self:get_achievement_object(achievement_const.harvest_wool)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:harvest_honeycomb(count)
    local achievement_object = self:get_achievement_object(achievement_const.harvest_honeycomb)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:harvest_bacon(count)
    local achievement_object = self:get_achievement_object(achievement_const.harvest_bacon)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:build_farmland(count)
    local achievement_object = self:get_achievement_object(achievement_const.build_farmland)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:harvest_farmland(count)
    local achievement_object = self:get_achievement_object(achievement_const.harvest_farmland)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:add_friends(friends_count)
    local achievement_object = self:get_achievement_object(achievement_const.add_friends)
    achievement_object:refresh_finish_times(friends_count)
end

function AchievementRuler:continue_login(times)
    local achievement_object = self:get_achievement_object(achievement_const.continue_login)
    achievement_object:refresh_finish_times(times)
end

function AchievementRuler:limit_sale_barn(timestamp,count)
    local achievement_object = self:get_achievement_object(achievement_const.limit_sale_barn)
    achievement_object:refresh_record_object(timestamp)
    achievement_object:add_record_object(timestamp,count)
end

function AchievementRuler:limit_harvest_farmland(timestamp,count)
    local achievement_object = self:get_achievement_object(achievement_const.limit_harvest_farmland)
    achievement_object:refresh_record_object(timestamp)
    achievement_object:add_record_object(timestamp,count)
end

function AchievementRuler:limit_helicopter_order(timestamp,count)
    local achievement_object = self:get_achievement_object(achievement_const.limit_helicopter_order)
    achievement_object:refresh_record_object(timestamp)
    achievement_object:add_record_object(timestamp,count)
end

function AchievementRuler:open_undevelop(count)
    local achievement_object = self:get_achievement_object(achievement_const.open_undevelop)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:create_road(count)
    local achievement_object = self:get_achievement_object(achievement_const.create_road)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:purchase_market(count)
    local achievement_object = self:get_achievement_object(achievement_const.purchase_market)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:levelup_worker(count)
    local achievement_object = self:get_achievement_object(achievement_const.levelup_worker)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:help_count(count)
    local achievement_object = self:get_achievement_object(achievement_const.help_count)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:continue_flight(count)
    local achievement_object = self:get_achievement_object(achievement_const.continue_flight)
    achievement_object:refresh_finish_times(count)
end

function AchievementRuler:flight_money(count)
    local achievement_object = self:get_achievement_object(achievement_const.flight_money)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:seaport_order(count)
    local achievement_object = self:get_achievement_object(achievement_const.seaport_order)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:seaport_reward(count)
    local achievement_object = self:get_achievement_object(achievement_const.seaport_reward)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:lucky_house(count)
    local achievement_object = self:get_achievement_object(achievement_const.lucky_house)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:cost_gem(count)
    local achievement_object = self:get_achievement_object(achievement_const.cost_gem)
    achievement_object:add_finish_times(count)
end

function AchievementRuler:finish_helicopter_record()
    self.__finish_helicopter = self.__finish_helicopter + 1
end

function AchievementRuler:finish_trains_record()
    self.__finish_trains = self.__finish_trains + 1
end

function AchievementRuler:finish_flight_record()
    self.__finish_flight = self.__finish_flight + 1
end

function AchievementRuler:finish_ship_record()
    self.__finish_ship = self.__finish_ship + 1
end

function AchievementRuler:finish_product_record(count)
    self.__finish_product = self.__finish_product + count
end

function AchievementRuler:get_finish_trains()
    return self.__finish_trains
end

function AchievementRuler:get_finish_flight()
    return self.__finish_flight
end

function AchievementRuler:get_finish_ship()
    return self.__finish_ship
end

function AchievementRuler:get_finish_product()
    return self.__finish_product
end

function AchievementRuler:get_finish_helicopter()
    return self.__finish_helicopter
end

return AchievementRuler