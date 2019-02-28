local class = require "class"
local ProductObject = require "factory.product_object"
local StroageObject = require "factory.storage_object"
local factory_const = require "factory.factory_const"
local cjson = require "cjson"
local syslog = require "syslog"

local FactoryObject = class()

function FactoryObject:ctor(role_object,build_id,factory_entry)
    self.__role_object = role_object
    self.__build_id = build_id
    self.__factory_entry = factory_entry
    self.__product_slot = factory_entry:get_slot_count()
    self.__product_storage = factory_entry:get_storage_count()
    self.__max_slot = factory_entry:get_max_slot()
    self.__max_storage = factory_entry:get_max_storage()
    self.__product_quene = {}
    self.__storage_quene = {}
    self.__factory_attr = {}
end

function FactoryObject:load_factory_object(factory_object)
    self.__product_slot = factory_object.product_slot
    self.__product_storage = factory_object.product_storage
    local product_quene  = factory_object.product_quene
    local storage_quene  = factory_object.storage_quene
    local factory_attr  = factory_object.factory_attr
    self:load_product_quene(product_quene)
    self:load_storage_quene(storage_quene)
    self:load_factory_attr(factory_attr)
end

function FactoryObject:load_product_quene(product_quene)
    for i,v in ipairs(product_quene) do
        local timestamp = v.timestamp
        local product_time = v.product_time
        local product_index = v.product_index
        local harvest_time = v.harvest_time
        local status = v.status
        local product_object = ProductObject.new(self.__role_object,product_time,timestamp,product_index)
        product_object:set_status(status)
        product_object:set_harvest_time(harvest_time)
        table.insert(self.__product_quene,product_object)
    end
end

function FactoryObject:load_storage_quene(storage_quene)
    for i,v in pairs(storage_quene) do
        local timestamp = v.timestamp
        local product_index = v.product_index
        local slot_index = v.slot_index
        local storage_object = StroageObject.new(timestamp,product_index,slot_index)
        self.__storage_quene[slot_index] = storage_object
    end
end

function FactoryObject:get_current_product()
    return self.__product_quene[1]
end

function FactoryObject:get_last_product()
    local count = #self.__product_quene
    return self.__product_quene[count]
end

function FactoryObject:load_factory_attr(encode_data)
    if not encode_data then return end
    self.__factory_attr = cjson.decode(encode_data)
end

function FactoryObject:set_factory_attr(key,value)
    self.__factory_attr[key] = value
end

function FactoryObject:get_factory_attr(key,default)
    return self.__factory_attr[key] or default
end

function FactoryObject:get_worker_id()
    return self:get_factory_attr("worker_id",0)
end

function FactoryObject:set_worker_id(worker_id)
    self:set_factory_attr("worker_id",worker_id)
end

function FactoryObject:check_can_add_worker(timestamp)
    local worker_id = self:get_worker_id()
    return worker_id <= 0
end

function FactoryObject:employment_worker_object(worker_id,timestamp)
    if not self:check_can_add_worker(timestamp) then
        LOG_ERROR("worker_id:%d timestamp:%s error:%s",worker_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_add_worker))
        return GAME_ERROR.cant_add_worker
    end
    local employment_ruler = self.__role_object:get_employment_ruler()
    local worker_object = employment_ruler:get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    self:set_worker_id(worker_id)
    worker_object:set_build_id(self.__build_id)
    self:refresh_factory_object(timestamp)
    self:refresh_product_time(timestamp)
    return 0
end

function FactoryObject:get_off_work(timestamp)
    local worker_id = self:get_worker_id()
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(worker_id)
    if not worker_object then
        LOG_ERROR("timestamp:%s error:%s",get_epoch_time(timestamp),errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    self:refresh_factory_object(timestamp)
    self:refresh_get_off_work(timestamp)
    self:set_worker_id()
    worker_object:get_off_work()
    return 0
end

function FactoryObject:refresh_product_time(timestamp)
    local product_object = self:get_current_product()
    if not product_object then return end
    local worker_id = self:get_worker_id()
    local employment_ruler = self.__role_object:get_employment_ruler()
    local worker_object = employment_ruler:get_worker_object(worker_id)
    local accelerate = 1 
    local current_time = 0
    if worker_object then
        accelerate = worker_object:get_accelerate() * 0.01 + 1
    end
    for i,product_object in ipairs(self.__product_quene) do
        if i == 1 then
            local harvest_time = product_object:get_harvest_time()
            local remain_time = math.floor((harvest_time - timestamp) / accelerate)
            harvest_time = timestamp + remain_time
            product_object:set_harvest_time(harvest_time)
            current_time = harvest_time
        else
            product_object:set_product_time(current_time)
            local finish_time = product_object:get_finish_time()
            local harvest_time = current_time + math.floor(finish_time / accelerate)
            product_object:set_harvest_time(harvest_time)
            current_time = harvest_time
        end
    end
end


function FactoryObject:refresh_get_off_work(timestamp)
    local product_object = self:get_current_product()
    if not product_object then return end
    local worker_id = self:get_worker_id()
    local employment_ruler = self.__role_object:get_employment_ruler()
    local worker_object = employment_ruler:get_worker_object(worker_id)
    local accelerate = 1 
    local current_time = 0
    if worker_object then
        accelerate = worker_object:get_accelerate() * 0.01 + 1
    end
    for i,product_object in ipairs(self.__product_quene) do
        if i == 1 then
            local harvest_time = product_object:get_harvest_time()
            local remain_time = math.floor((harvest_time - timestamp) * (accelerate))
            harvest_time = timestamp + remain_time
            product_object:set_harvest_time(harvest_time)
            current_time = harvest_time
        else
            product_object:set_product_time(current_time)
            local finish_time = product_object:get_finish_time()
            local harvest_time = current_time + finish_time
            product_object:set_harvest_time(harvest_time)
            current_time = harvest_time
        end
    end
end

function FactoryObject:dump_factory_object()
    local factory_object = {}
    factory_object.build_id = self.__build_id
    factory_object.product_slot = self.__product_slot
    factory_object.product_storage = self.__product_storage
    factory_object.product_quene = self.dump_product_quene(self)
    factory_object.storage_quene = self.dump_storage_quene(self)
    factory_object.factory_attr = self.dump_factory_attr(self)
    return factory_object
end

function FactoryObject:dump_product_quene()
    local data = {}
    for k,v in ipairs(self.__product_quene) do
        table.insert(data,v:dump_product_object())
    end
    return data
end

function FactoryObject:dump_storage_quene()
    local data = {}
    for k,v in pairs(self.__storage_quene) do
        table.insert(data,v:dump_storage_object())
    end
    return data
end

function FactoryObject:dump_factory_attr()
    return cjson.encode(self.__factory_attr)
end

function FactoryObject:get_factory_index()
    return self.__factory_entry:get_factory_index()
end

function FactoryObject:check_can_product()
    return #self.__product_quene < self.__product_slot
end

function FactoryObject:check_can_storage()
    for i=1,self.__product_storage do
        if not self.__storage_quene[i] then return true end
    end
    return false
end

function FactoryObject:get_storage_index()
    for i=1,self.__product_storage do
        if not self.__storage_quene[i] then return i end
    end
end

function FactoryObject:recalc_product_time(timestamp)
    local current_time = timestamp
    local worker_id = self:get_worker_id()
    local employment_ruler = self.__role_object:get_employment_ruler()
    local worker_object = employment_ruler:get_worker_object(worker_id)
    local accelerate = 1
    if worker_object then
        accelerate = worker_object:get_accelerate() * 0.01 + 1
    end
    for i,product_object in ipairs(self.__product_quene) do
        product_object:set_product_time(current_time)
        local finish_time = product_object:get_finish_time()
        local remain_time = math.floor(finish_time / accelerate)
        local harvest_time = current_time + remain_time  
        product_object:set_harvest_time(harvest_time)
        current_time = harvest_time
    end
end

function FactoryObject:refresh_factory_object(timestamp)
    local product_object = self:get_current_product()
    if not product_object then return end
    if not self:check_can_storage() then return end
    if product_object:check_pause() then
        product_object:start_product()
        self:recalc_product_time(timestamp)
    end
    if product_object:check_finish(timestamp) then
        table.remove(self.__product_quene,1) 
        local harvest_time = product_object:get_harvest_time()
        local product_index = product_object:get_product_index()
        local slot_index = self:get_storage_index()
        local multiple = product_object:get_multiple()
        local storage_object = StroageObject.new(harvest_time,product_index,slot_index,multiple)
        self.__storage_quene[slot_index] = storage_object
        local next_product_object = self:get_current_product()
        if not next_product_object then return end
        if not self:check_can_storage() then
            next_product_object:set_pause()
        end
        self:refresh_factory_object(timestamp)
    end
end
    
function FactoryObject:check_product_index(product_index)
    return self.__factory_entry:check_product_index(product_index)
end

function FactoryObject:add_product(timestamp,product_index,item_objects)
    self:refresh_factory_object(timestamp)
    if not self:check_can_product() then
        LOG_ERROR("product_index:%d timestamp:%s error:%s",product_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.production_queue_full))
        return GAME_ERROR.production_queue_full
    end
    if not self:check_product_index(product_index) then
        LOG_ERROR("product_index:%d timestamp:%s error:%s",product_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.production_not_exist))
        return GAME_ERROR.production_not_exist 
    end
    local factory_ruler = self.__role_object:get_factory_ruler()
    local product_entry = factory_ruler:get_product_entry(product_index)
    if not product_entry then
        LOG_ERROR("product_index:%d timestamp:%s error:%s",product_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.production_not_exist))
        return GAME_ERROR.production_not_exist 
    end
    local level = product_entry:get_unlock_level()
    local formula = product_entry:get_formula()
    if not self.__role_object:check_level(level) then
        LOG_ERROR("product_index:%d timestamp:%s unlock_level:%d error:%s",product_index,get_epoch_time(timestamp),level,errmsg(GAME_ERROR.level_not_enough))
        return GAME_ERROR.level_not_enough 
    end
    local consume_itmes = {}
    for i,item_object in ipairs(item_objects) do
        consume_itmes[item_object.item_index] = item_object.item_count
    end
    for k,v in pairs(formula) do
        if consume_itmes[k] ~= v then
            LOG_ERROR("product_index:%d timestamp:%s item_index:%d formula_count:%d consume_count:%d error:%s",product_index,get_epoch_time(timestamp),k,v,consume_itmes[k] or 0,errmsg(GAME_ERROR.number_not_match))
            return GAME_ERROR.number_not_match 
        end
        if not self.__role_object:check_enough_item(k,v) then
            LOG_ERROR("product_index:%d timestamp:%s error:%s",product_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.formula_not_enough))
            return GAME_ERROR.formula_not_enough
        end
    end
    for k,v in pairs(formula) do
        self.__role_object:consume_item(k,v,CONSUME_CODE.product)
    end
    local product_time = timestamp
    local last_product_object = self:get_last_product()
    if last_product_object then
        product_time = last_product_object:get_harvest_time()
    end
    local product_object = ProductObject.new(self.__role_object,product_time,timestamp,product_index)
    local employment_ruler = self.__role_object:get_employment_ruler()
    local worker_id = self:get_worker_id()
    local worker_object = employment_ruler:get_worker_object(worker_id)
    local accelerate = 1
    if worker_object then
        accelerate = worker_object:get_accelerate() * 0.01 + 1
    end
    local finish_time = product_object:get_finish_time()
    local harvest_time = product_time + math.floor(finish_time/accelerate)
    product_object:set_harvest_time(harvest_time)
    local item_count = product_entry:get_product_count()
    self.__role_object:get_daily_ruler():factory_product(item_count)
    table.insert(self.__product_quene,product_object)
    if not self:check_can_storage() then
        product_object:set_pause()
    end
    self:refresh_factory_object(timestamp)
    return 0
end

function FactoryObject:promote_product_object(timestamp,product_index,cash_count)
    self:refresh_factory_object(timestamp)
    local product_object = self:get_current_product()
    if not product_object then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.product_not_exist))
        return GAME_ERROR.product_not_exist 
    end
    local current_product_index = product_object:get_product_index()
    if current_product_index ~= product_index then
        LOG_ERROR("current_product_index:%d product_index:%d err:%s",current_product_index,product_index,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match 
    end
    if not product_object:check_can_promote() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote
    end
    local remain_time = product_object:get_harvest_time() - timestamp
    local cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if cash ~= cash_count then
        LOG_ERROR("cash:%d cash_count:%d err:%s",cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match 
    end
    if not self.__role_object:check_enough_cash(cash) then
        LOG_ERROR("cash:%d err:%s",cash,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.cash_not_enough 
    end
    self.__role_object:consume_cash(cash,CONSUME_CODE.promote)
    product_object:set_status(factory_const.promote)
    table.remove(self.__product_quene,1) 
    local product_index = product_object:get_product_index()
    local slot_index = self:get_storage_index()
    local multiple = 0
    local storage_object = StroageObject.new(timestamp,product_index,slot_index,multiple)
    self.__storage_quene[slot_index] = storage_object
    self:recalc_product_time(timestamp)
    local next_product_object = self:get_current_product()
    if not next_product_object then return 0 end
    if not self:check_can_storage() then
        next_product_object:set_pause()
    end
    return 0
end

function FactoryObject:harvest_product_object(timestamp,product_index,slot_index)
    self:refresh_factory_object(timestamp)
    local storage_object = self.__storage_quene[slot_index]
    if not storage_object then
        LOG_ERROR("slot_index:%d err:%s",slot_index,errmsg(GAME_ERROR.storage_not_exist))
        return GAME_ERROR.storage_not_exist 
    end
    local storage_product_index = storage_object:get_product_index()
    if  storage_product_index ~= product_index then 
        LOG_ERROR("storage_product_index:%d product_index:%d err:%s",storage_product_index,product_index,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    local product_entry = self.__role_object:get_factory_ruler():get_product_entry(product_index)
    assert(product_entry)
    local exp = product_entry:get_product_exp()
    local product_count = product_entry:get_product_count()
    local item_count = storage_object:get_multiple() + product_count
    if not self.__role_object:get_item_ruler():check_item_capacity(item_count) then
        LOG_ERROR("item_count:%d err:%s",item_count,errmsg(GAME_ERROR.item_capacity_not_enough))
        return GAME_ERROR.item_capacity_not_enough
    end
    self.__role_object:add_exp(exp,SOURCE_CODE.harvest)
    self.__role_object:add_item(product_index,item_count,SOURCE_CODE.harvest)
    self.__role_object:get_achievement_ruler():factory_product(item_count)
    self.__role_object:get_achievement_ruler():finish_product_record(item_count)
    self.__role_object:get_daily_ruler():factory_storage(item_count)
    self.__role_object:get_daily_ruler():seven_harvest_factory(item_count)
    self.__storage_quene[slot_index] = nil
    self:refresh_factory_object(timestamp)
    return 0
end

function FactoryObject:start_product(product_objects)
    if not product_objects then return end
    for i,product_object in ipairs(product_objects) do
        local timestamp = product_object.timestamp
        local product_index = product_object.product_index
        local item_objects = product_object.item_objects or {}
        local result = self:add_product(timestamp,product_index,item_objects)
        if result > 0 then return result end
    end
    return 0
end

function FactoryObject:harvest_product(storage_objects)
    if not storage_objects then return end
    for i,storage_object in ipairs(storage_objects) do
        local timestamp = storage_object.timestamp
        local product_index = storage_object.product_index
        local slot_index = storage_object.slot_index
        local result = self:harvest_product_object(timestamp,product_index,slot_index)
        if result > 0 then return result end
    end
    return 0
end

function FactoryObject:promote_product(product_object)
    if not product_object then return end
    local timestamp = product_object.timestamp
    local product_index = product_object.product_index
    local cash_count = product_object.cash_count
    local result = self:promote_product_object(timestamp,product_index,cash_count)
    return result
end

function FactoryObject:check_can_add_slot(slot_index)
    local max_slot_count = self.__factory_entry:get_max_slot()
    return (self.__product_slot + 1 == slot_index) and (slot_index <= max_slot_count)
end

function FactoryObject:add_product_slot(slot_index,cash_count)
    local cash = self.__factory_entry:get_slot_cost(slot_index)
    if cash ~= cash_count then
        LOG_ERROR("cash:%d cash_count:%d err:%s",cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match 
    end
    if not self:check_can_add_slot(slot_index) then
        LOG_ERROR("slot_index:%d err:%s",slot_index,errmsg(GAME_ERROR.cant_add_slot))
        return GAME_ERROR.cant_add_slot 
    end
    if not self.__role_object:check_enough_cash(cash) then
        LOG_ERROR("cash:%d err:%s",cash,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.cash_not_enough  
    end
    self.__role_object:consume_cash(cash,CONSUME_CODE.add_slot)
    self.__product_slot = self.__product_slot + 1
    return 0 
end

function FactoryObject:debug_info()
    local factory_info = ""
    factory_info = factory_info.."build_id:"..self.__build_id.."\n"
    factory_info = factory_info.."product_slot:"..self.__product_slot.."\n"
    factory_info = factory_info.."product_storage:"..self.__product_storage.."\n"
    local product_quene = "\n\n"
    for i,product_object in pairs(self.__product_quene) do
        product_quene = product_quene..product_object:debug_info().."\n"
    end
    local storage_quene = "\n"
    for k,storage_object in pairs(self.__storage_quene) do
        storage_quene = storage_quene..storage_object:debug_info().."\n"
    end
    factory_info = factory_info.."product_quene:"..product_quene.."\n"
    factory_info = factory_info.."storage_quene:"..storage_quene.."\n"
    factory_info = factory_info.."factory_attr:"..self:dump_factory_attr().."\n"
    return factory_info
end

return FactoryObject