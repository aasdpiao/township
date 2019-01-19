local class = require "class"

local AnimalObject = class()

local animal_state = {}
animal_state.hunger = 0
animal_state.feed = 1
animal_state.promote = 2

function AnimalObject:ctor(role_object,slot_index,feed_entry)
	self.__role_object = role_object
	self.__timestamp = 0
	self.__slot_index = slot_index
	self.__product_index = feed_entry:get_product_index()
	self.__feed_entry = feed_entry
	self.__status = animal_state.hunger
	self.__harvest_time = 0
end

function AnimalObject:dump_animal_object()
	local animal_object = {}
	animal_object.timestamp = self.__timestamp
	animal_object.slot_index = self.__slot_index
	animal_object.status = self.__status
	animal_object.harvest_time = self.__harvest_time
	return animal_object
end

function AnimalObject:load_animal_object(animal_object)
	self.__timestamp = animal_object.timestamp
	self.__slot_index = animal_object.slot_index
	self.__status = animal_object.status
	self.__harvest_time = animal_object.harvest_time
end

function AnimalObject:feed_animal(time_stamp)
	self.__timestamp = time_stamp
	self.__status = animal_state.feed
	self.__role_object:get_daily_ruler():feed_animal()
end

function AnimalObject:get_feed_time()
	return self.__timestamp
end

function AnimalObject:check_can_feed()
	return self.__status == animal_state.hunger
end

function AnimalObject:get_finish_time()
	return self.__feed_entry:get_finish_time()
end

function AnimalObject:set_harvest_time(harvest_time)
	self.__harvest_time = harvest_time
end

function AnimalObject:get_harvest_time()
	return self.__harvest_time
end

function AnimalObject:check_can_harvest(timestamp)
	if self.__status == animal_state.promote then return true end
	return timestamp >= self.__harvest_time
end

function AnimalObject:check_can_promote(timestamp)
	return self.__status == animal_state.feed
end

function AnimalObject:get_slot_index()
	return self.__slot_index
end

function AnimalObject:get_finish_cash(timestamp)
	local remain_time = self.__harvest_time - timestamp
    local need_cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
	return need_cash
end

function AnimalObject:start_breed(timestamp,item_objects,worker_id)
	local employment_ruler = self.__role_object:get_employment_ruler()
	local worker_object = employment_ruler:get_worker_object(worker_id)
	local accelerate = 1 
	if worker_object then
    	accelerate = worker_object:get_accelerate() * 0.01 + 1
	end
	local formula = self.__feed_entry:get_formula()
	for item_index,item_count in pairs(formula) do
		if item_count ~= item_objects[item_index] then 
			LOG_ERROR("worker_id:%d timestamp:%s item_index:%d formula_count:%d consume_count:%d error:%s",worker_id,get_epoch_time(timestamp),item_index,item_count,item_objects[item_index] or 0,errmsg(GAME_ERROR.number_not_match))
            return GAME_ERROR.number_not_match 
		end
		if not self.__role_object:check_enough_item(item_index,item_count) then
			LOG_ERROR("item_index:%d timestamp:%s error:%s",item_index,get_epoch_time(timestamp),errmsg(GAME_ERROR.formula_not_enough))
            return GAME_ERROR.formula_not_enough
		end
	end
	for item_index,item_count in pairs(formula) do
		self.__role_object:consume_item(item_index,item_count,CONSUME_CODE.feed)
	end
	self:feed_animal(timestamp)
	local finish_time = self:get_finish_time()
	local harvest_time = timestamp + math.floor(finish_time / accelerate)
	self:set_harvest_time(harvest_time)
	return 0
end

function AnimalObject:harvest_breed()
	self.__status = animal_state.hunger
	local item_index = self.__feed_entry:get_product_item()
	local product_exp = self.__feed_entry:get_product_exp()
	local item_count = 1
	if not self.__role_object:get_item_ruler():check_item_capacity(item_count) then
        LOG_ERROR("item_count:%d err:%s",item_count,errmsg(GAME_ERROR.item_capacity_not_enough))
        return GAME_ERROR.item_capacity_not_enough
    end
	self.__role_object:add_item(item_index,item_count,SOURCE_CODE.harvest)
	self.__role_object:add_exp(product_exp,SOURCE_CODE.harvest)
	self.__role_object:get_daily_ruler():feed_harvest()
	if item_index == 2001 then
		self.__role_object:get_achievement_ruler():harvest_milk(item_count)
	elseif item_index == 2002 then
		self.__role_object:get_achievement_ruler():harvest_egg(item_count)
	elseif item_index == 2003 then
		self.__role_object:get_achievement_ruler():harvest_wool(item_count)
	elseif item_index == 2004 then
		self.__role_object:get_achievement_ruler():harvest_honeycomb(item_count)
	elseif item_index == 2005 then
		self.__role_object:get_achievement_ruler():harvest_bacon(item_count)
	end
	return 0
end

function AnimalObject:promote_breed()
	self.__status = animal_state.promote
	return 0
end

return AnimalObject