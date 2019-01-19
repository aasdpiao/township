local class = require "class"
local MarketManager = require "market.market_manager"
local BusinessmanObject = require "market.businessman_object"
local OrderObject = require "market.order_object"
local SaleObject = require "market.sale_object"
local MarketDispatcher = require "market.market_dispatcher"
local packer = require "db.packer"
local utils = require "utils"

local DEFAULTCOUNT = 6
local TIMEINTERVAL = 6 * 60 * 60
local REFRESHCASH = 6

local MarketRuler = class()

function MarketRuler:ctor(role_object)
    self.__role_object = role_object
    self.__status = 0
    self.__worker_id = 0
    self.__businessman_object = nil
    self.__expand_count = 0
    self.__sale_objects = {}
    self.__timestamp = 0
end

function MarketRuler:init()
    self.__market_manager = MarketManager.new(self.__role_object)
    self.__market_manager:init()
    
    self.__market_dispatcher = MarketDispatcher.new(self.__role_object)
    self.__market_dispatcher:init()
end

function MarketRuler:load_market_data(market_data)
    if not market_data then return end
    local code = packer.decode(market_data)
    local worker_id = code.worker_id or 0
    local expand_count = code.expand_count or 0
    local sale_objects = code.sale_objects or {}
    local timestamp = code.timestamp or 0
    local status = code.status or 0
    local businessman_object = code.businessman_object
    self.__worker_id = worker_id
    self.__expand_count = expand_count
    self.__status = status
    self.__timestamp = timestamp
    self:load_sale_objects(sale_objects)
    self:load_businessman_object(businessman_object)
end

function MarketRuler:dump_market_data()
    local market_data = {}
    market_data.worker_id = self.__worker_id
    market_data.expand_count = self.__expand_count
    market_data.status = self.__status
    market_data.timestamp = self.__timestamp
    market_data.sale_objects = self:dump_sale_objects()
    if self.__businessman_object then
        market_data.businessman_object = self.__businessman_object:dump_businessman_object()
    end
    return market_data
end

function MarketRuler:load_sale_objects(sale_objects)
    for i,v in ipairs(sale_objects) do
        local sale_index = v.sale_index
        local item_count = v.item_count
        local status = v.status
        local sale_entry = self:get_sale_entry(sale_index)
        local sale_object = SaleObject.new(self.__role_object,sale_entry,item_count)
        sale_object:set_status(status)
        self.__sale_objects[i] = sale_object
    end
end

function MarketRuler:load_businessman_object(businessman_data)
    if not businessman_data then return end
    local businessman_index = businessman_data.businessman_index
    local timestamp = businessman_data.timestamp
    local expire_time = businessman_data.expire_time
    local commodity_objects = businessman_data.commodity_objects
    self.__businessman_object = BusinessmanObject.new(self.__role_object,businessman_index)
    self.__businessman_object:load_businessman_object(timestamp,expire_time,commodity_objects)
end

function MarketRuler:dump_sale_objects()
    local sale_objects  = {}
    for i,v in ipairs(self.__sale_objects) do
        sale_objects[i] = v:dump_sale_object() 
    end
    return sale_objects
end

function MarketRuler:get_slot_count()
    return DEFAULTCOUNT + self.__expand_count
end

function MarketRuler:serialize_market_data()
    local market_data = self.dump_market_data(self)
    return packer.encode(market_data)
end

function MarketRuler:check_can_add_worker(timestamp)
    return self.__worker_id <= 0
end

function MarketRuler:employment_worker_object(worker_id,timestamp)
    if not self:check_can_add_worker(timestamp) then
        LOG_ERROR("worker_id:%d timestamp:%s error:%s",worker_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_add_worker))
        return GAME_ERROR.cant_add_worker
    end
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    self.__worker_id = worker_id
    worker_object:set_build_id(5005001)
    return 0
end

function MarketRuler:get_off_work(timestamp)
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if not worker_object then
        LOG_ERROR("timestamp:%s error:%s",get_epoch_time(timestamp),errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    self.__worker_id = 0
    worker_object:get_off_work()
    return 0
end

function MarketRuler:get_businessman_entry(businessman_index)
    return self.__market_manager:get_businessman_entry(businessman_index)
end

function MarketRuler:get_expand_entry(unlock_index)
    return self.__market_manager:get_expand_entry(unlock_index)
end

function MarketRuler:get_sale_entry(sale_index)
    return self.__market_manager:get_sale_entry(sale_index)
end

function MarketRuler:generate_sale_objects(timestamp)
    self.__timestamp = timestamp
    local count = self:get_slot_count()
    self.__sale_objects = self.__market_manager:generate_sale_objects(count)
end

function MarketRuler:unlock_market(timestamp)
    if not self:check_can_unlock() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_unlock))
        return GAME_ERROR.cant_unlock
    end
    self.__status = 1
    self:generate_sale_objects(timestamp)
    return 0
end

function MarketRuler:check_can_unlock()
    return self.__status == 0
end

function MarketRuler:get_refresh_timestamp()
    return self.__timestamp
end

function MarketRuler:check_can_add_slot(slot_index)
    if self.__expand_count + 1 ~= slot_index then return false end
    return slot_index <= 39
end

function MarketRuler:request_market(timestamp)
    if self.__status ~= 1 then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.operate_not_unlock))
        return GAME_ERROR.operate_not_unlock
    end
    if self.__timestamp + TIMEINTERVAL > timestamp then return 0 end
    local remain_time = timestamp - self.__timestamp
    local count = math.floor(remain_time/TIMEINTERVAL)
    local generate_time = self.__timestamp + TIMEINTERVAL * count
    self:generate_sale_objects(generate_time)
    return 0
end

function MarketRuler:refresh_market(timestamp,cash_count)
    if self.__status ~= 1 then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.operate_not_unlock))
        return GAME_ERROR.operate_not_unlock
    end
    if self.__timestamp + TIMEINTERVAL < timestamp then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_refresh))
        return GAME_ERROR.cant_refresh
    end
    local remain_time = self.__timestamp + TIMEINTERVAL - timestamp
    local refresh_cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if refresh_cash ~= cash_count then
        LOG_ERROR("refresh_cash:%d cash_count:%d err:%s",refresh_cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_cash(cash_count) then
        LOG_ERROR("cash_count:%d err:%s",cash_count,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.cash_not_enough
    end
    self.__role_object:consume_cash(cash_count,CONSUME_CODE.refresh)
    self:generate_sale_objects(timestamp)
    return 0
end

function MarketRuler:buy_sale(sale_index,gold_count)
    if self.__status ~= 1 then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.operate_not_unlock))
        return GAME_ERROR.operate_not_unlock
    end
    local sale_object = self.__sale_objects[sale_index]
    if not sale_object then
        LOG_ERROR("sale_index:%d err:%s",sale_index,errmsg(GAME_ERROR.sale_not_exist))
        return GAME_ERROR.sale_not_exist
    end
    local sale_price = sale_object:get_sale_price()
    if sale_price ~= gold_count then
        LOG_ERROR("sale_price:%d gold_count:%d err:%s",sale_price,gold_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_gold(gold_count) then
        LOG_ERROR("gold_count:%d err:%s",gold_count,errmsg(GAME_ERROR.gold_not_enough))
        return GAME_ERROR.gold_not_enough
    end
    if not sale_object:check_can_buy() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_buy))
        return GAME_ERROR.cant_buy
    end
    local item_index = sale_object:get_item_index()
    local item_count = sale_object:get_item_count()
    if not self.__role_object:get_item_ruler():check_item_capacity(item_count) then
        LOG_ERROR("item_count:%d err:%s",item_count,errmsg(GAME_ERROR.item_capacity_not_enough))
        return GAME_ERROR.item_capacity_not_enough
    end
    self.__role_object:consume_gold(gold_count,CONSUME_CODE.market)
    self.__role_object:add_item(item_index,item_count,SOURCE_CODE.market)
    self.__role_object:get_achievement_ruler():purchase_market(1)
    self.__role_object:get_daily_ruler():market_buy(1)
    sale_object:buy_sale()
    return 0
end

function MarketRuler:check_can_employ_businessman(timestamp)
    if not self.__businessman_object then return true end
    return not self.__businessman_object:check_employ_expire(timestamp)
end

function MarketRuler:employ_businessman(timestamp,businessman_index,cash_count)
    if not self:check_can_employ_businessman(timestamp) then 
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_employ))
        return GAME_ERROR.cant_employ
    end
    local businessman_entry = self:get_businessman_entry(businessman_index)
    if not businessman_entry then
        LOG_ERROR("businessman_index:%d err:%s",businessman_index,errmsg(GAME_ERROR.businessman_not_exist))
        return GAME_ERROR.businessman_not_exist
    end
    local employ_cash = businessman_entry:get_employ_cash()
    if employ_cash ~= cash_count then
        LOG_ERROR("employ_cash:%d cash_count:%d err:%s",employ_cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_cash(cash_count) then
        LOG_ERROR("cash_count:%d err:%s",cash_count,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.cash_not_enough
    end
    self.__role_object:consume_cash(cash_count,CONSUME_CODE.employ_businessman)
    self.__businessman_object = BusinessmanObject.new(self.__role_object,businessman_index)
    self.__businessman_object:set_employ_time(timestamp)
    return 0
end

function MarketRuler:search_commodity(timestamp,sale_index)
    if not self.__businessman_object then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.businessman_not_exist))
        return GAME_ERROR.businessman_not_exist
    end
    if not self.__businessman_object:check_employ_expire(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.businessman_not_exist))
        return GAME_ERROR.businessman_not_exist
    end
    if not self.__businessman_object:check_can_search(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_search))
        return GAME_ERROR.cant_search
    end
    local sale_entry = self:get_sale_entry(sale_index)
    if not sale_entry then
        LOG_ERROR("sale_index:%d err:%s",sale_index,errmsg(GAME_ERROR.sale_not_exist))
        return GAME_ERROR.sale_not_exist
    end
    local level = self.__role_object:get_level()
    if not sale_entry:check_level(level) then
        LOG_ERROR("level:%d err:%s",level,errmsg(GAME_ERROR.level_not_enough))
        return GAME_ERROR.level_not_enough
    end
    self.__businessman_object:set_commodity_counts(sale_entry)
    return 0
end

function MarketRuler:get_commodity_objects()
    return self.__businessman_object:dump_commodity_objects()
end

function MarketRuler:buy_commodity(timestamp,commodity_index,sale_index,item_count,sale_price)
    if not self.__businessman_object then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.businessman_not_exist))
        return GAME_ERROR.businessman_not_exist
    end
    local commodity_object = self.__businessman_object:get_commodity_object(commodity_index)
    if not commodity_object then
        LOG_ERROR("commodity_index:%d err:%s",commodity_index,errmsg(GAME_ERROR.sale_not_exist))
        return GAME_ERROR.sale_not_exist
    end
    local commodity_sale_index = commodity_object:get_sale_index()
    if commodity_sale_index ~= sale_index then
        LOG_ERROR("commodity_sale_index:%d sale_index:%d err:%s",commodity_sale_index,sale_index,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    local commodity_item_count = commodity_object:get_item_count()
    if commodity_item_count ~= item_count then
        LOG_ERROR("commodity_item_count:%d item_count:%d err:%s",commodity_item_count,item_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    local price = commodity_object:get_sale_price() * item_count
    if price ~= sale_price then
        LOG_ERROR("price:%d sale_price:%d err:%s",price,sale_price,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    local item_index = commodity_object:get_item_index()
    if not self.__role_object:check_enough_gold(sale_price) then
        LOG_ERROR("sale_price:%d err:%s",sale_price,errmsg(GAME_ERROR.gold_not_enough))
        return GAME_ERROR.gold_not_enough
    end
    if not self.__role_object:get_item_ruler():check_item_capacity(item_count) then
        LOG_ERROR("item_count:%d err:%s",item_count,errmsg(GAME_ERROR.item_capacity_not_enough))
        return GAME_ERROR.item_capacity_not_enough
    end
    self.__role_object:consume_gold(sale_price,CONSUME_CODE.commodity)
    self.__businessman_object:set_buy_commodity(timestamp)
    self.__role_object:add_item(item_index,item_count,SOURCE_CODE.commodity)
    return 0
end

function MarketRuler:add_market_slot(slot_index,cash_count)
    if not self:check_can_add_slot(slot_index) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_add_slot))
        return GAME_ERROR.cant_add_slot
    end
    local expand_entry = self:get_expand_entry(slot_index)
    local cost_cash = expand_entry:get_unlock_cash()
    if cash_count ~= cost_cash then
        LOG_ERROR("cost_cash:%d cash_count:%d err:%s",cost_cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_cash(cash_count) then
        LOG_ERROR("cash_count:%d err:%s",cash_count,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.cash_not_enough
    end
    self.__role_object:consume_cash(cash_count)
    self.__expand_count = self.__expand_count + 1
    local sale_object = self.__market_manager:generate_sale_object()
    table.insert( self.__sale_objects, sale_object )
    return 0
end

return MarketRuler