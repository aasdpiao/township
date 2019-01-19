local class = require "class"
local HelicopterManager = require "helicopter.helicopter_manager"
local HelicopterDispatcher = require "helicopter.helicopter_dispatcher"
local OrderObject = require "helicopter.order_object"
local packer = require "db.packer"

local DELETETIME = 30 * 60

local HelicopterRuler = class()

function HelicopterRuler:ctor(role_object)
    self.__role_object = role_object

    self.__worker_id = 0
    self.__station_status = 0
    self.__order_objects = {}
end

function HelicopterRuler:init()
    self.__helicopter_manager = HelicopterManager.new(self.__role_object)
    self.__helicopter_manager:init()
    
    self.__helicopter_dispatcher = HelicopterDispatcher.new(self.__role_object)
    self.__helicopter_dispatcher:init()
end

function HelicopterRuler:load_helicopter_data(helicopter_data)
    if not helicopter_data then return end
    local code = packer.decode(helicopter_data)
    local worker_id = code.worker_id or 0
    local station_status = code.station_status or 0
    local order_objects = code.order_objects or {}
    self.__worker_id = worker_id
    self.__station_status = station_status
    self:load_order_objects(order_objects)
end

function HelicopterRuler:load_order_objects(order_objects)
    for i,v in ipairs(order_objects) do
        local order_boxes = v.order_boxes
        local person_index = v.person_index
        local timestamp = v.timestamp
        local status = v.status
        local order_object = OrderObject.new(self.__role_object,order_boxes)
        order_object:set_person_index(person_index)
        order_object:set_timestamp(timestamp)
        order_object:set_status(status)
        self.__order_objects[i] = order_object
    end
end

function HelicopterRuler:dump_helicopter_data()
    local helicopter_data = {}
    helicopter_data.worker_id = self.__worker_id
    helicopter_data.station_status = self.__station_status
    helicopter_data.order_objects = self:dump_order_objects()
    return helicopter_data
end

function HelicopterRuler:dump_order_objects()
    local order_objects = {}
    for i,v in ipairs(self.__order_objects) do
        order_objects[i] = v:dump_order_object()
    end
    return order_objects
end

function HelicopterRuler:serialize_helicopter_data()
    local helicopter_data = self.dump_helicopter_data(self)
    return packer.encode(helicopter_data)
end

function HelicopterRuler:check_can_add_worker(timestamp)
    return self.__worker_id <= 0
end

function HelicopterRuler:employment_worker_object(worker_id,timestamp)
    if not self:check_can_add_worker(timestamp) then
        LOG_ERROR("worker_id:%d timestamp:%s error:%s",worker_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_add_worker))
        return GAME_ERROR.cant_add_worker
    end
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    self.__worker_id = worker_id
    worker_object:set_build_id(5003001)
    self:refresh_delete_time(true,timestamp)
    return 0
end

function HelicopterRuler:get_off_work(timestamp)
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if not worker_object then
        LOG_ERROR("timestamp:%s error:%s",get_epoch_time(timestamp),errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    self:refresh_delete_time(false,timestamp)
    self.__worker_id = 0
    worker_object:get_off_work()
    return 0
end

function HelicopterRuler:refresh_delete_time(employ,timestamp)
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if not worker_object then
        LOG_ERROR("error:%s",errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    local accelerate = worker_object:get_accelerate() * 0.01 + 1
    if employ then
        for i,v in pairs(self.__order_objects) do
            if v:get_status() == 1 and timestamp < v:get_timestamp() then
                local accelerate_time = (v:get_timestamp() - timestamp)/accelerate
                v:set_timestamp(timestamp + math.floor(accelerate_time))
            end
        end
    else
        for i,v in pairs(self.__order_objects) do
            if v:get_status() == 1 and timestamp < v:get_timestamp() then
                local accelerate_time = (v:get_timestamp() - timestamp) * accelerate
                v:set_timestamp(timestamp + math.floor(accelerate_time))
            end
        end
    end
end

function HelicopterRuler:get_order_entry(order_index)
    return self.__helicopter_manager:get_order_entry(order_index)
end

function HelicopterRuler:check_can_unlock()
    return self.__station_status == 0
end

function HelicopterRuler:unlock_helicopter()
    if not self:check_can_unlock() then return 101 end
    self.__station_status = 1 
    self:first_order_object()
    return 0
end

function HelicopterRuler:first_order_object()
    local order_boxes = {{order_index=1001,item_count=5}}
    local order_object = OrderObject.new(self.__role_object,order_boxes)
    local person_index = self:generate_person_index()
    order_object:set_person_index(person_index)
    self.__order_objects[1] = order_object
    self:refresh_order_object()
end

function HelicopterRuler:request_helicopter()
    self:refresh_order_object()
    return 0
end

function HelicopterRuler:get_order_count()
    local count = 0
    for k,v in pairs(self.__order_objects) do
        count = count + 1
    end
    return count
end

function HelicopterRuler:generate_person_index()
    local person_entrys = {}
    for i,v in ipairs(self.__order_objects) do
        local person_index = v:get_person_index()
        person_entrys[person_index] = true
    end
    local person_index = self.__helicopter_manager:generate_person_index(person_entrys)
    return person_index
end

function HelicopterRuler:refresh_order_object()
    local count = self.__helicopter_manager:get_order_count()
    local order_count = self:get_order_count()
    if order_count >= count then return end
    local order_object = self.__helicopter_manager:generate_order_object()
    local person_index = self:generate_person_index()
    order_object:set_person_index(person_index)
    table.insert( self.__order_objects, order_object )
    self:refresh_order_object()
end

function HelicopterRuler:delete_helicopter_order(timestamp,order_index)
    local order_object = self.__order_objects[order_index]
    if not order_object then
        LOG_ERROR("order_index:%d err:%s",order_index,errmsg(GAME_ERROR.order_not_exist))
        return GAME_ERROR.order_not_exist
    end
    if not order_object:check_can_delete(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_delete))
        return GAME_ERROR.cant_delete
    end
    local order_object = self.__helicopter_manager:generate_order_object()
    local person_index = self:generate_person_index()
    order_object:set_person_index(person_index)
    self.__order_objects[order_index] = order_object
    local accelerate = 1
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if worker_object then
        accelerate = worker_object:get_accelerate() * 0.01 + 1
    end
    order_object:set_timestamp(timestamp + math.floor(DELETETIME/accelerate))
    order_object:set_status(1)
    self.__role_object:get_daily_ruler():refresh_helicopter()
    return 0
end

function HelicopterRuler:promote_helicopter_order(timestamp,order_index,cash_count)
    local order_object = self.__order_objects[order_index]
    if not order_object then
        LOG_ERROR("order_index:%d err:%s",order_index,errmsg(GAME_ERROR.order_not_exist))
        return GAME_ERROR.order_not_exist
    end
    if not order_object:check_can_promote(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote
    end
    local remain_time = order_object:get_timestamp() - timestamp
    local cost_cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if cost_cash ~= cash_count then
        LOG_ERROR("cost_cash:%d cash_count:%d err:%s",cost_cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    order_object:set_timestamp(0)
    order_object:set_status(0)
    return 0
end

function HelicopterRuler:finish_helicopter_order(order_index,item_objects,gold_count,timestamp)
    local order_object = self.__order_objects[order_index]
    if not order_object then
        LOG_ERROR("order_index:%d err:%s",order_index,errmsg(GAME_ERROR.order_not_exist))
        return GAME_ERROR.order_not_exist
    end
    if not order_object:check_can_finish(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    local items = {}
    for i,v in ipairs(item_objects) do
        local item_index = v.item_index
        local item_count = v.item_count
        items[item_index] = item_count
    end
    local order_boxes = order_object:get_order_boxes()
    local sale_gold = 0
    local add_exp = 0
    for i,v in ipairs(order_boxes) do
        local item_index = v:get_item_index()
        local item_count = v:get_item_count()
        if items[item_index] ~= item_count then
            LOG_ERROR("item_index:%d,item_count:%d,cost_item_count:%d,err:%s",item_index,item_count,items[item_index],errmsg(GAME_ERROR.number_not_match))
            return GAME_ERROR.number_not_match
        end
        sale_gold = sale_gold + v:get_sale_price()
        add_exp = add_exp + v:get_sale_exp()
        if not self.__role_object:check_enough_item(item_index,item_count) then
            LOG_ERROR("item_index:%d,item_count:%d,err:%s",item_index,item_count,errmsg(GAME_ERROR.item_not_enough))
            return GAME_ERROR.item_not_enough
        end
    end
    if sale_gold ~= gold_count then
        LOG_ERROR("sale_gold:%d,gold_count:%d,err:%s",sale_gold,gold_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    for k,v in pairs(items) do
        self.__role_object:consume_item(k,v,CONSUME_CODE.finish_order)
    end
    self.__role_object:add_exp(add_exp,SOURCE_CODE.finish)
    self.__role_object:add_gold(sale_gold,SOURCE_CODE.finish)
    self.__role_object:get_achievement_ruler():finish_helicopter_order()
    self.__role_object:get_achievement_ruler():limit_helicopter_order(timestamp,1)
    self.__role_object:get_achievement_ruler():finish_helicopter_record()
    self.__role_object:get_daily_ruler():finish_helicopter()
    local order_object = self.__helicopter_manager:generate_order_object()
    local person_index = self:generate_person_index()
    order_object:set_person_index(person_index)
    self.__order_objects[order_index] = order_object
    return 0
end

return HelicopterRuler 