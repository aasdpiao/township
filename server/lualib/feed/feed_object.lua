local class = require "class"
local AnimalObject = require "feed.animal_object"
local syslog =require "syslog"
local cjson = require "cjson"
local FeedObject = class()

function FeedObject:ctor(role_object,build_id,build_entry)
    self.__role_object = role_object
    self.__build_id = build_id
    self.__build_entry = build_entry

    self.__slot_count = build_entry:get_slot_count()
    self.__max_slot_count = build_entry:get_max_slot()

    self.__products = build_entry:get_products()

    self.__animal_objects = {}

    self.__feed_attr = {}
end

function FeedObject:get_product_index()
    for k,v in pairs(self.__products) do
        return k
    end
end

function FeedObject:get_animal_object(slot_index)
    local animal_object = self.__animal_objects[slot_index]
    if not animal_object then
        local product_index = self:get_product_index()
        assert(product_index,"product_index is nil")
        local feed_entry = self.__role_object:get_feed_ruler():get_feed_entry(product_index)
        animal_object = AnimalObject.new(self.__role_object,slot_index,feed_entry)
        self.__animal_objects[slot_index] = animal_object
    end
    return animal_object
end

function FeedObject:load_feed_object(feed_object)
    self.__slot_count = feed_object.slot_count or self.__build_entry:get_slot_count()
    local animal_objects = feed_object.animal_objects
    for slot_index,v in ipairs(animal_objects) do
        local animal_object = self:get_animal_object(slot_index)
        animal_object:load_animal_object(v)
    end
    local feed_attr = feed_object.feed_attr
    self:load_feed_attr(feed_attr)
end

function FeedObject:dump_feed_object()
    local feed_object = {}
    feed_object.build_id = self.__build_id
    feed_object.slot_count = self.__slot_count
    feed_object.animal_objects = {}
    for k,animal_object in pairs(self.__animal_objects) do
        table.insert(feed_object.animal_objects,animal_object:dump_animal_object())
    end
    feed_object.feed_attr = self:dump_feed_attr()
    return feed_object
end

function FeedObject:load_feed_attr(encode_data)
    if not encode_data then return end
    self.__feed_attr = cjson.decode(encode_data)
end

function FeedObject:dump_feed_attr()
    return cjson.encode(self.__feed_attr)
end

function FeedObject:set_feed_attr(key,value)
    self.__feed_attr[key] = value
end

function FeedObject:get_feed_attr(key,default)
    return self.__feed_attr[key] or default
end

function FeedObject:get_worker_id()
    return self:get_feed_attr("worker_id",0)
end

function FeedObject:set_worker_id(worker_id)
    self:set_feed_attr("worker_id",worker_id)
end

function FeedObject:check_can_add_worker(timestamp)
    local worker_id = self:get_worker_id()
    return worker_id <= 0
end

function FeedObject:employment_worker_object(worker_id,timestamp)
    if not self:check_can_add_worker(timestamp) then
        LOG_ERROR("worker_id:%d timestamp:%s error:%s",worker_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_add_worker))
        return GAME_ERROR.cant_add_worker
    end
    local employment_ruler = self.__role_object:get_employment_ruler()
    local worker_object = employment_ruler:get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    self:set_worker_id(worker_id)
    worker_object:set_build_id(self.__build_id)
    self:refresh_harvest_time(timestamp)
    return 0
end

function FeedObject:get_off_work(timestamp)
    local worker_id = self:get_worker_id()
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(worker_id)
    if not worker_object then
        LOG_ERROR("timestamp:%s error:%s",get_epoch_time(timestamp),errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    self:refresh_get_off_work(timestamp)
    self:set_worker_id()
    worker_object:get_off_work()
    return 0
end

function FeedObject:refresh_get_off_work(timestamp)
    local worker_id = self:get_worker_id()
    local employment_ruler = self.__role_object:get_employment_ruler()
	local worker_object = employment_ruler:get_worker_object(worker_id)
	local accelerate = 1 
	if worker_object then
    	accelerate = worker_object:get_accelerate() * 0.01 + 1
	end
    for k,animal_object in pairs(self.__animal_objects) do
        local harvest_time = animal_object:get_harvest_time()
        local remain_time = harvest_time - timestamp 
        if remain_time > 0 then
            harvest_time = timestamp + math.ceil(remain_time * accelerate)
            animal_object:set_harvest_time(harvest_time)
        end
    end
end

function FeedObject:refresh_harvest_time(timestamp)
    local worker_id = self:get_worker_id()
    local employment_ruler = self.__role_object:get_employment_ruler()
	local worker_object = employment_ruler:get_worker_object(worker_id)
	local accelerate = 1 
	if worker_object then
    	accelerate = worker_object:get_accelerate() * 0.01 + 1
	end
    for k,animal_object in pairs(self.__animal_objects) do
        local harvest_time = animal_object:get_harvest_time()
        local remain_time = harvest_time - timestamp 
        if remain_time > 0 then
            harvest_time = timestamp + math.ceil(remain_time / accelerate)
            animal_object:set_harvest_time(harvest_time)
        end
    end
end

function FeedObject:check_can_add_slot(slot_index)
    return (self.__slot_count + 1 == slot_index) and (slot_index <= self.__max_slot_count)
end

function FeedObject:start_breed(animal_object)
    local timestamp = animal_object.timestamp
    local slot_index = animal_object.slot_index
    local item_objects = animal_object.item_objects
    local formula = {}
    for k,v in ipairs(item_objects) do
        formula[v.item_index] = v.item_count
    end
    local animal_object = self.get_animal_object(self,slot_index)
    if not animal_object:check_can_feed() then
        LOG_ERROR("slot_index:%d timestamp:%s error:%s",slot_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_feed_operate))
        return GAME_ERROR.cant_feed_operate 
    end
    local worker_id = self:get_worker_id()
    local result = animal_object:start_breed(timestamp,formula,worker_id)
    return result
end

function FeedObject:harvest_breed(animal_object)
    local timestamp = animal_object.timestamp
    local slot_index = animal_object.slot_index
    local animal_object = self.get_animal_object(self,slot_index)
    if not animal_object:check_can_harvest(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_harvest))
        return GAME_ERROR.cant_harvest
    end
    local result = animal_object:harvest_breed()
    return result
end

function FeedObject:promote_breed(animal_object)
    local timestamp = animal_object.timestamp
    local slot_index = animal_object.slot_index
    local cash_count = animal_object.cash_count
    local animal_object = self.get_animal_object(self,slot_index)
    if not animal_object:check_can_promote(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote 
    end
    local need_cash = animal_object:get_finish_cash(timestamp)
    if need_cash ~= cash_count then
        LOG_ERROR("cash:%d cash_count:%d err:%s",need_cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match 
    end
    self.__role_object:consume_cash(cash_count,CONSUME_CODE.promote)
    local result = animal_object:promote_breed()
    return result
end

function FeedObject:add_breed_slot(slot_index,gold_count)
    local gold = self.__build_entry:get_slot_cost(slot_index)
    if gold ~= gold_count then
        LOG_ERROR("gold:%d gold_count:%d err:%s",gold,gold_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match 
    end
    if not self:check_can_add_slot(slot_index) then
        LOG_ERROR("slot_index:%d err:%s",slot_index,errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_add_slot 
    end
    if not self.__role_object:check_enough_gold(gold) then
        LOG_ERROR("gold:%d err:%s",gold,errmsg(GAME_ERROR.gold_not_enough))
        return GAME_ERROR.gold_not_enough 
    end
    self.__role_object:consume_gold(gold,CONSUME_CODE.add_slot)
    self.__slot_count = self.__slot_count + 1
    return 0
end

return FeedObject