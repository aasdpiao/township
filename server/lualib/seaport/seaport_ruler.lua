local class = require "class"
local SeaportManager = require "seaport.seaport_manager"
local SeaportDispatcher = require "seaport.seaport_dispatcher"
local IslandObject = require "seaport.island_object"
local ShipObject = require "seaport.ship_object"
local packer = require "db.packer"
local syslog = require "syslog"

local SeaportRuler = class()

function SeaportRuler:ctor(role_object)
    self.__role_object = role_object

    self.__worker_id = 0
    self.__station_status = 0
    self.__timestamp = 0

    self.__island_objects = {}
    self.__ship_objects = {}
end

function SeaportRuler:init()
    self.__seaport_manager = SeaportManager.new(self.__role_object)
    self.__seaport_manager:init()
    
    self.__seaport_dispatcher = SeaportDispatcher.new(self.__role_object)
    self.__seaport_dispatcher:init()
end

function SeaportRuler:get_seaport_manager()
    return self.__seaport_manager
end

function SeaportRuler:load_seaport_data(seaport_data)
    if not seaport_data then return end
    local code = packer.decode(seaport_data)
    local worker_id = code.worker_id or 0
    local station_status = code.station_status or 0
    local timestamp = code.timestamp or 0
    local island_objects = code.island_objects or {}
    local ship_objects = code.ship_objects or {}

    self.__worker_id = worker_id
    self.__station_status = station_status
    self.__timestamp = timestamp
    self:load_island_objects(island_objects)
    self:load_ship_objects(ship_objects)
end

function SeaportRuler:load_island_objects(island_objects)
    for i,v in ipairs(island_objects) do
        local island_index = v.island_index
        local island_entry = self:get_island_entry(island_index)
        local island_object = IslandObject.new(self.__role_object,island_entry)
        island_object:load_island_object(v)
        self.__island_objects[island_index] = island_object
    end
end

function SeaportRuler:load_ship_objects(ship_objects)
    for i,v in ipairs(ship_objects) do
        local ship_index = v.ship_index
        local ship_entry = self:get_ship_entry(ship_index)
        local ship_object = ShipObject.new(self.__role_object,ship_entry)
        ship_object:load_ship_object(v)
        self.__ship_objects[ship_index] = ship_object
    end
end

function SeaportRuler:dump_seaport_data()
    local seaport_data = {}
    seaport_data.worker_id = self.__worker_id
    seaport_data.station_status = self.__station_status
    seaport_data.timestamp = self.__timestamp
    seaport_data.island_objects = self:dump_island_objects()
    seaport_data.ship_objects = self:dump_ship_objects()
    return seaport_data
end

function SeaportRuler:dump_island_objects()
    local island_objects = {}
    for k,v in pairs(self.__island_objects) do
        local island_object = v:dump_island_object()
        table.insert( island_objects, island_object)
    end
    return island_objects
end

function SeaportRuler:dump_ship_objects()
    local ship_objects = {}
    for k,v in pairs(self.__ship_objects) do
        local ship_object = v:dump_ship_object()
        table.insert(ship_objects,ship_object)
    end
    return ship_objects
end

function SeaportRuler:serialize_seaport_data()
    local seaport_data = self.dump_seaport_data(self)
    return packer.encode(seaport_data)
end

function SeaportRuler:get_ship_object(ship_index)
    return self.__ship_objects[ship_index]
end

function SeaportRuler:get_island_object(island_index)
    return self.__island_objects[island_index]
end

function SeaportRuler:get_ship_entry(ship_index)
    return self.__seaport_manager:get_ship_entry(ship_index)
end

function SeaportRuler:get_island_entry(island_index)
    return self.__seaport_manager:get_island_entry(island_index)
end

function SeaportRuler:check_can_add_worker(timestamp)
    return self.__worker_id <= 0
end

function SeaportRuler:employment_worker_object(worker_id,timestamp)
    if not self:check_can_add_worker(timestamp) then
        LOG_ERROR("worker_id:%d timestamp:%s error:%s",worker_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_add_worker))
        return GAME_ERROR.cant_add_worker
    end
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    self.__worker_id = worker_id
    worker_object:set_build_id(5007001)
    return 0
end

function SeaportRuler:get_off_work(timestamp)
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if not worker_object then
        LOG_ERROR("timestamp:%s error:%s",get_epoch_time(timestamp),errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    self.__worker_id = 0
    worker_object:get_off_work()
    return 0
end

function SeaportRuler:get_gold_entry()
    return self.__seaport_manager:get_gold_entry()
end

function SeaportRuler:get_unlock_gold()
    local build_id = 5007001 
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
    return unlock_entry:get_gold()
end

function SeaportRuler:get_finish_time()
    local build_id = 5007001 
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
    return unlock_entry:get_finish_time()
end

function SeaportRuler:get_unlock_exp()
    local build_id = 5007001 
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
    return unlock_entry:get_product_exp()
end

function SeaportRuler:get_require_formula()
    local build_index = 5007
    local build_require = self.__role_object:get_grid_ruler():get_build_require(build_index)
    local require_formula = build_require:get_require_formula()
    return require_formula
end

function SeaportRuler:check_can_unlock()
    local build_id = 5007001 
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
    local unlock_level = unlock_entry:get_level()
    if not self.__role_object:check_level(unlock_level) then return false end
    local unlock_gold = unlock_entry:get_gold()
    if not self.__role_object:check_enough_gold(unlock_gold) then return false end
    return self.__station_status == 0
end

function SeaportRuler:unlock_seaport(timestamp,gold_count)
    if not self:check_can_unlock() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_unlock))
        return GAME_ERROR.cant_unlock
    end
    local unlock_gold = self:get_unlock_gold()
    if gold_count ~= unlock_gold then
        LOG_ERROR("gold_count:%d unlock_gold:%d err:%s",gold_count,unlock_gold,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    self.__role_object:consume_gold(unlock_gold,CONSUME_CODE.unlock)
    self.__role_object:get_achievement_ruler():cost_city_money(unlock_gold)
    self.__station_status = 1
    self.__timestamp = timestamp
    return 0
end

function SeaportRuler:check_can_finish(timestamp)
    if self.__station_status == 3 then return true end
    if self.__station_status ~= 1 then return false end
    local finish_time = self:get_finish_time()
    return self.__timestamp + finish_time <= timestamp
end

function SeaportRuler:check_can_promote(timestamp)
    if self.__station_status ~= 1 then return false end
    local finish_time = self:get_finish_time()
    return self.__timestamp + finish_time > timestamp
end

function SeaportRuler:promote_seaport(timestamp,cash_count)
    if not self:check_can_promote(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote
    end
    local finish_time = self:get_finish_time()
    local remain_time = self.__timestamp + finish_time - timestamp
    local cost_cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if cash_count ~= cost_cash then
        LOG_ERROR("cash:%d cash_count:%d err:%s",cash_count,cost_cash,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_cash(cash_count) then
        LOG_ERROR("cash_count:%d err:%s",cash_count,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.cash_not_enough
    end
    self.__role_object:consume_cash(cash_count,CONSUME_CODE.promote)
    self.__station_status = 3
    return 0
end

function SeaportRuler:finish_seaport(timestamp,item_objects)
    if not self:check_can_finish(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    local items = {}
    for i,v in ipairs(item_objects) do
        local item_index = v.item_index
        local item_count = v.item_count
        items[item_index] = item_count
    end
    local formula = self:get_require_formula()
    for k,v in pairs(formula) do
        if items[k] ~= v then
            LOG_ERROR("item_index:%d item_count:%d formula_count:%d err:%s",k,items[k],v,errmsg(GAME_ERROR.number_not_match))
            return GAME_ERROR.number_not_match
        end
        if not self.__role_object:check_enough_item(k,v) then
            LOG_ERROR("item_index:%d item_count:%d err:%s",k,v,errmsg(GAME_ERROR.item_not_enough))
            return GAME_ERROR.item_not_enough
        end 
    end

    for k,v in pairs(formula) do
        self.__role_object:consume_item(k,v,CONSUME_CODE.finish_order)
    end

    local unlock_exp = self:get_unlock_exp()
    self.__role_object:add_exp(unlock_exp,SOURCE_CODE.finish)

    self.__island_objects = self.__seaport_manager:generate_island_objects()
    local ship_index = 5008001
    local ship_entry = self.__seaport_manager:get_ship_entry(ship_index)
    local ship_object = ShipObject.new(self.__role_object,ship_entry)
    self.__ship_objects[ship_index] = ship_object
    self.__station_status = 2
    return 0
end

function SeaportRuler:set_sail(ship_index,timestamp,island_index,gold_count,commodity_objects)
    local ship_object = self:get_ship_object(ship_index)
    local island_object = self:get_island_object(island_index)
    if not ship_object then
        LOG_ERROR("ship_index:%d err:%s",ship_index,errmsg(GAME_ERROR.ship_not_exist))
        return GAME_ERROR.ship_not_exist
    end
    if not ship_object:check_can_set_sail() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_set_sail))
        return GAME_ERROR.cant_set_sail
    end
    if not island_object then
        LOG_ERROR("island_index:%d err:%s",island_index,errmsg(GAME_ERROR.island_not_exist))
        return GAME_ERROR.island_not_exist
    end
    if not island_object:check_can_set_sail(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_set_sail))
        return GAME_ERROR.cant_set_sail
    end
    local cost_gold = island_object:get_set_sail_gold()
    if cost_gold ~= gold_count then
        LOG_ERROR("cost_gold:%d gold_count:%d err:%s",cost_gold,gold_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_gold(cost_gold) then
        LOG_ERROR("cost_gold:%d err:%s",cost_gold,errmsg(GAME_ERROR.gold_not_enough))
        return GAME_ERROR.gold_not_enough
    end
    for i,v in ipairs(commodity_objects) do
        local item_index = v.item_index
        local item_count = v.item_count
        if not self.__role_object:check_enough_item(item_index,item_count) then
            LOG_ERROR("item_index:%d item_count:%d err:%s",item_index,item_count,errmsg(GAME_ERROR.item_not_enough))
            return GAME_ERROR.item_not_enough
        end
    end
    self.__role_object:consume_gold(gold_count,CONSUME_CODE.set_sail)
    for i,v in ipairs(commodity_objects) do
        local item_index = v.item_index
        local item_count = v.item_count
        self.__role_object:consume_item(item_index,item_count,CONSUME_CODE.set_sail)
    end
    local multiple = island_object:get_multiple()
    local reward_objects = island_object:get_reward_objects()
    ship_object:set_island_index(island_index)
    ship_object:set_commodity_objects(commodity_objects)
    ship_object:set_reward_objects(reward_objects)
    ship_object:set_multiple(multiple)
    ship_object:set_sail(timestamp)
    self.__role_object:get_achievement_ruler():seaport_order(1)
    self.__role_object:get_daily_ruler():set_sail()
    island_object:set_ship_index(ship_index)
    island_object:set_sail(timestamp)
    return 0
end

function SeaportRuler:promote_set_sail(ship_index,timestamp,cash_count)
    local ship_object = self:get_ship_object(ship_index)
    if not ship_object then
        LOG_ERROR("ship_index:%d err:%s",ship_index,errmsg(GAME_ERROR.ship_not_exist))
        return GAME_ERROR.ship_not_exist
    end
    if not ship_object:check_can_promote(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote
    end
    local remain_time = ship_object:get_remain_time(timestamp)
    local cost_cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if cost_cash ~= cash_count then
        LOG_ERROR("cost_cash:%d cash_count:%d err:%s",cost_cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_cash(cash_count) then
        LOG_ERROR("cash_count:%d err:%s",cash_count,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.cash_not_enough
    end
    self.__role_object:consume_cash(cash_count,CONSUME_CODE.promote)
    ship_object:promote_set_sail()
    local island_index = ship_object:get_island_index()
    local island_object = self:get_island_object(island_index)
    island_object:harvest_ship()
    return 0
end

function SeaportRuler:harvest_ship(ship_index,timestamp,reward_objects)
    local ship_object = self:get_ship_object(ship_index)
    if not ship_object then
        LOG_ERROR("ship_index:%d err:%s",ship_index,errmsg(GAME_ERROR.ship_not_exist))
        return GAME_ERROR.ship_not_exist
    end
    if not ship_object:check_can_harvest(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_harvest))
        return GAME_ERROR.cant_harvest
    end
    local rewards = ship_object:get_reward_objects()
    for i,v in ipairs(reward_objects) do
        local reward_index = v.reward_index
        local reward_object = rewards[reward_index]
        local item_index = reward_object:get_item_index()
        local item_count = reward_object:get_item_count()
        self.__role_object:add_item(item_index,item_count,SOURCE_CODE.harvest)
        self.__role_object:get_achievement_ruler():seaport_reward(item_count)
        self.__role_object:get_daily_ruler():harvest_ship(item_count)
        local exp = reward_object:get_exp_count()
        self.__role_object:add_exp(exp,SOURCE_CODE.harvest)
        reward_object:set_status(1)
    end
    if ship_object:check_harvest_finish() then
        ship_object:harvest_ship()
    end
    return 0
end

function SeaportRuler:refresh_harbor(island_index,timestamp)
    local island_object = self:get_island_object(island_index)
    if not island_object then
        LOG_ERROR("island_index:%d err:%s",island_index,errmsg(GAME_ERROR.island_not_exist))
        return GAME_ERROR.island_not_exist
    end
    if not island_object:check_can_refresh(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_refresh))
        return GAME_ERROR.cant_refresh
    end
    island_object:refresh_harbor(timestamp)
    return 0
end

function SeaportRuler:promote_harbor(island_index,timestamp,cash_count)
    local island_object = self:get_island_object(island_index)
    if not island_object then
        LOG_ERROR("island_index:%d err:%s",island_index,errmsg(GAME_ERROR.island_not_exist))
        return GAME_ERROR.island_not_exist
    end
    if not island_object:check_can_promote(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote
    end
    local remain_time = island_object:get_remain_time(timestamp)
    local cost_cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if cost_cash ~= cash_count then
        LOG_ERROR("cost_cash:%d cash_count:%d err:%s",cost_cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    self.__role_object:consume_cash(cash_count)
    island_object:promote_harbor()
    return 0
end

function SeaportRuler:add_ship(ship_index,gold_count)
    local ship_entry = self.__seaport_manager:get_ship_entry(ship_index)
    local unlock_gold = ship_entry:get_unlock_gold()
    local unlock_level = ship_entry:get_unlock_level()
    local unlock_people = ship_entry:get_unlock_people()
    if gold_count ~= unlock_gold then
        LOG_ERROR("gold_count:%d unlock_gold:%d err:%s",gold_count,unlock_gold,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_level(unlock_level) then
        LOG_ERROR("unlock_level:%d err:%s",unlock_level,errmsg(GAME_ERROR.level_not_enough))
        return GAME_ERROR.level_not_enough
    end
    if not self.__role_object:check_enough_gold(unlock_gold) then
        LOG_ERROR("unlock_gold:%d err:%s",unlock_gold,errmsg(GAME_ERROR.gold_not_enough))
        return GAME_ERROR.gold_not_enough
    end
    if not self.__role_object:check_people(unlock_people) then
        LOG_ERROR("unlock_people:%d err:%s",unlock_people,errmsg(GAME_ERROR.people_not_enough))
        return GAME_ERROR.people_not_enough
    end
    self.__role_object:consume_gold(unlock_gold,CONSUME_CODE.buy_ship)
    local ship_object = ShipObject.new(self.__role_object,ship_entry)
    self.__ship_objects[ship_index] = ship_object
    return 0
end

return SeaportRuler