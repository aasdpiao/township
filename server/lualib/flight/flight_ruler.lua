local class = require "class"
local FlightManager = require "flight.flight_manager"
local FlightDispatcher = require "flight.flight_dispatcher"
local packer = require "db.packer"
local OrderObject = require "flight.order_object"
local RewardObject = require "flight.reward_object"

local FLIGHTINTERVAL = 20 * 60 * 60
local FLIGHTVALID = 15 * 60 * 60
local FLIGHTBACK = 5 * 60 * 60

local FlightRuler = class()

function FlightRuler:ctor(role_object)
    self.__role_object = role_object
    self.__station_status = 0   --0未解锁 1开始建造 2加速 3订单生成 4飞机飞走 5等待返回
    self.__timestamp = 0
    self.__worker_id = 0
    self.__order_objects = {}
    self.__order_rewards = {}
end

function FlightRuler:init()
    self.__flight_manager = FlightManager.new(self.__role_object)
    self.__flight_manager:init()
    
    self.__flight_dispatcher = FlightDispatcher.new(self.__role_object)
    self.__flight_dispatcher:init()
end

function FlightRuler:load_flight_data(flight_data)
    if not flight_data then return end
    local code = packer.decode(flight_data)
    self.__timestamp = code.timestamp or 0
    self.__station_status = code.station_status or 0
    local order_objects = code.flight_orders or {}
    local order_rewards = code.flight_rewards or {}
    self:load_order_rewards(order_rewards)
    self:load_order_objects(order_objects)
end

function FlightRuler:load_order_objects(order_objects)
    for i,v in ipairs(order_objects) do
        local order_boxes = v.order_boxes
        local order_object = OrderObject.new(self.__role_object,{})
        order_object:load_order_boxes(order_boxes)
        self.__order_objects[i] = order_object
    end
end

function FlightRuler:load_order_rewards(order_rewards)
    for i,v in ipairs(order_rewards) do
        local status = v.status
        local item_objects = v.item_objects
        local order_reward = RewardObject.new(self.__role_object,item_objects)
        order_reward:set_status(status)
        self.__order_rewards[i] = order_reward
    end
end

function FlightRuler:dump_flight_data()
    local flight_data = {}
    flight_data.station_status = self.__station_status or 0
    flight_data.timestamp = self.__timestamp or 0
    flight_data.worker_id = self.__worker_id or 0
    flight_data.flight_orders = self:dump_order_objects()
    flight_data.flight_rewards = self:dump_order_rewards()
    return flight_data
end

function FlightRuler:get_order_entry(order_index)
    return self.__flight_manager:get_order_entry(order_index)
end

function FlightRuler:dump_order_objects()
    local order_objects = {}
    for i,v in ipairs(self.__order_objects) do
        local order_object = v:dump_order_object()
        table.insert( order_objects, order_object )
    end
    return order_objects
end

function FlightRuler:dump_order_rewards()
    local order_rewards = {}
    for i,v in ipairs(self.__order_rewards) do
        local order_reward = v:dump_reward_object()
        table.insert( order_rewards, order_reward )
    end
    return order_rewards
end

function FlightRuler:check_can_take_off(timestamp)
    return self.__station_status == 3
end

function FlightRuler:get_station_status()
    return self.__station_status
end

function FlightRuler:get_timestamp()
    return self.__timestamp
end

function FlightRuler:check_can_unlock()
    local build_id = 5002001
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
    local unlock_level = unlock_entry:get_level()
    if not self.__role_object:check_level(unlock_level) then return false end
    if self.__station_status ~= 0 then return false end
    local unlock_gold = unlock_entry:get_gold()
    if not self.__role_object:check_enough_gold(unlock_gold) then return false end
    return true
end

function FlightRuler:check_can_promote(timestamp)
    if self.__station_status ~= 1 then return false end
    local build_id = 5002001
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
    local finish_time = unlock_entry:get_finish_time()
    if self.__timestamp + finish_time <= timestamp then return false end
    return true
end

function FlightRuler:get_unlock_gold()
    local build_id = 5002001
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
    return unlock_entry:get_gold()
end

function FlightRuler:get_product_exp()
    local build_id = 5002001
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
    return unlock_entry:get_product_exp()
end

function FlightRuler:get_finish_time()
    local build_id = 5002001
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(build_id)
    local finish_time = unlock_entry:get_finish_time()
    return finish_time
end

function FlightRuler:get_require_formula()
    local build_index = 5002
    local build_require = self.__role_object:get_grid_ruler():get_build_require(build_index)
    local require_formula = build_require:get_require_formula()
    return require_formula
end

function FlightRuler:unlock_station(timestamp,gold_count)
    local unlock_gold = self:get_unlock_gold()
    if unlock_gold ~= gold_count then
        LOG_ERROR("unlock_gold:%d gold_count:%d err:%s",unlock_gold,gold_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    self.__role_object:consume_gold(gold_count,CONSUME_CODE.unlock)
    self.__role_object:get_achievement_ruler():cost_city_money(gold_count)
    self.__station_status = 1
    self.__timestamp = timestamp
    return 0
end

function FlightRuler:check_can_finish(timestamp)
    if self.__station_status == 2 then return true end
    if self.__station_status ~= 1 then return false end
    local build_index = 5002
    local build_require = self.__role_object:get_grid_ruler():get_build_require(build_index)
    local finish_time = build_require:get_finish_time()
    return self.__timestamp + finish_time <= timestamp
end

function FlightRuler:generate_flight_order(timestamp)
    local order_objects = self.__flight_manager:generate_flight_order()
    for i=1,3 do
        local order_object = OrderObject.new(self.__role_object,order_objects)
        self.__order_objects[i] = order_object
    end
    local order_object1 = self.__order_objects[1]
    local value1 = math.ceil(order_object1:get_order_value()/2)
    local reward_object1 = RewardObject.new(self.__role_object,{{item_index=7001,item_count=value1}})
    local order_object2 = self.__order_objects[2]
    local value2 = order_object2:get_order_value()
    local reward_object2 = RewardObject.new(self.__role_object,{{item_index=7001,item_count=value2}})
    local order_object3 = self.__order_objects[3]
    local reward_items = self.__flight_manager:generate_rewards()
    local reward_object3 = RewardObject.new(self.__role_object,reward_items)
    self.__order_rewards[1] = reward_object1
    self.__order_rewards[2] = reward_object2
    self.__order_rewards[3] = reward_object3
    self.__timestamp = timestamp
    self.__station_status = 3
end

function FlightRuler:serialize_flight_data()
    local flight_data = self.dump_flight_data(self)
    return packer.encode(flight_data)
end

function FlightRuler:check_can_add_worker(timestamp)
    return self.__worker_id <= 0
end

function FlightRuler:employment_worker_object(worker_id,timestamp)
    if not self:check_can_add_worker(timestamp) then
        LOG_ERROR("worker_id:%d timestamp:%s error:%s",worker_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_add_worker))
        return GAME_ERROR.cant_add_worker
    end
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    self.__worker_id = worker_id
    worker_object:set_build_id(5002001)
    self:refresh_flight_back(true,timestamp)
    return 0
end

function FlightRuler:get_off_work(timestamp)
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if not worker_object then
        LOG_ERROR("timestamp:%s error:%s",get_epoch_time(timestamp),errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    self:refresh_flight_back(false,timestamp)
    self.__worker_id = 0
    worker_object:get_off_work()
    return 0
end

function FlightRuler:refresh_flight_back(employ,timestamp)
    if self.__station_status ~= 5 then return end
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if not worker_object then
        LOG_ERROR("error:%s",errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    local accelerate = worker_object:get_accelerate() * 0.01 + 1
    if employ then
        local remain_time = self.__timestamp - timestamp
        if remain_time > 0 then
            self.__timestamp = timestamp + math.floor(remain_time/accelerate)
        end
    else
        local remain_time = self.__timestamp - timestamp
        if remain_time > 0 then
            self.__timestamp = timestamp + math.floor(remain_time*accelerate)
        end
    end
end

function FlightRuler:promote_flight(cash_count,timestamp)
    if not self:check_can_promote(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote
    end
    local finish_time = self:get_finish_time()
    local remain_time = self.__timestamp + finish_time - timestamp
    local need_cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if need_cash ~= cash_count then
        LOG_ERROR("need_cash:%d cash_count:%d err:%s",need_cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_cash(need_cash) then
        LOG_ERROR("need_cash:%d err:%s",need_cash,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.cash_not_enough
    end
    self.__role_object:consume_cash(need_cash,CONSUME_CODE.promote) 
    self.__station_status = 2
    return 0
end

function FlightRuler:finish_flight(timestamp,item_objects)
    if not self:check_can_finish(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    local formula = self:get_require_formula()
    local consume_itmes = {}
    for i,item_object in ipairs(item_objects) do
        consume_itmes[item_object.item_index] = item_object.item_count
    end
    for k,v in pairs(formula) do
        if consume_itmes[k] ~= v then
            LOG_ERROR("item_index:%d item_count:%d formula_item_count err:%s",k,v,consume_itmes[k],errmsg(GAME_ERROR.number_not_match))
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
    local product_exp = self:get_product_exp()
    self.__role_object:add_exp(product_exp,SOURCE_CODE.finish)
    self:generate_flight_order(timestamp)
    return 0
end

function FlightRuler:get_order_box(row,column)
    local order_object = self.__order_objects[row]
    if not order_object then return end
    return order_object:get_order_box(column)
end

function FlightRuler:request_flight(timestamp)
    if self.__station_status == 3  then 
        if self.__timestamp + FLIGHTINTERVAL <= timestamp then
            self:generate_flight_order(timestamp)
            self.__role_object:set_continue_flight_order(0)
        elseif self.__timestamp + FLIGHTVALID <= timestamp then
            self:generate_flight_order(self.__timestamp + FLIGHTINTERVAL)
            self.__role_object:set_continue_flight_order(0)
            self.__station_status = 5
        end
    elseif self.__station_status == 4 then
        if self.__timestamp + FLIGHTBACK <= timestamp then
            self:generate_flight_order(timestamp)
        else
            local accelerate = 1
            local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
            if worker_object then
                accelerate = worker_object:get_accelerate() * 0.01 + 1
            end
            self:generate_flight_order(self.__timestamp + math.floor(FLIGHTBACK/accelerate))
            self.__station_status = 5
        end
    elseif self.__station_status == 5 then
        if self.__timestamp <= timestamp then
            self.__station_status = 3
        end
    end
    return 0
end

function FlightRuler:get_finish_order_count()
    local count = 0
    for i,v in ipairs(self.__order_objects) do
        if v:check_order_finish() then count = count + 1 end
    end
    return count
end

function FlightRuler:finish_flight_order(timestamp,row,column,item_object)
    if self.__station_status ~= 3 then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    if self.__timestamp + FLIGHTVALID < timestamp then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    local item_index = item_object.item_index
    local item_count = item_object.item_count
    local order_box = self:get_order_box(row,column)
    if not order_box then
        LOG_ERROR("row:%d column:%d err:%s",row,column,errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.order_not_exist
    end
    if order_box:check_order_finish() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    local order_item_index = order_box:get_item_index()
    local order_item_count = order_box:get_item_count()
    if order_item_index ~= item_index then
        LOG_ERROR("order_item_index:%d item_index:%d err:%s",order_item_index,item_index,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if order_item_count ~= item_count then
        LOG_ERROR("order_item_count:%d item_count:%d err:%s",order_item_count,item_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_item(item_index,item_count) then
        LOG_ERROR("item_index:%d item_count:%d err:%s",item_index,item_count,errmsg(GAME_ERROR.item_not_enough))
        return GAME_ERROR.item_not_enough
    end
    local gold = order_box:get_order_value()
    local exp = order_box:get_order_exp()
    self.__role_object:consume_item(item_index,item_count,CONSUME_CODE.finish_order)
    self.__role_object:add_exp(exp,SOURCE_CODE.finish)
    self.__role_object:add_gold(gold,SOURCE_CODE.finish)
    self.__role_object:get_achievement_ruler():flight_money(gold)
    order_box:finish_order()
    local order_object = self.__order_objects[row]
    local count = self:get_finish_order_count()
    if order_object:check_order_finish() then
        local reward_object = self.__order_rewards[count]
        if not reward_object:check_can_receive() then
            LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_reward))
            return GAME_ERROR.cant_reward
        end
        reward_object:receive_reward()
    end
    if count == 3 then
        self.__role_object:get_daily_ruler():finish_flight()
        self.__role_object:get_achievement_ruler():finish_flight_record()
        local contine_count = self.__role_object:get_continue_flight_order() + 1
        self.__role_object:set_continue_flight_order(contine_count)
        local max_count = self.__role_object:get_max_continue_flight()
        if contine_count > max_count then
            self.__role_object:set_max_continue_flight(contine_count)
            self.__role_object:get_achievement_ruler():continue_flight(contine_count)
        end
        local exp = self:get_finish_exp(timestamp)
        self.__role_object:add_exp(exp,SOURCE_CODE.reward)
        self.__station_status = 4
        self.__timestamp = timestamp
        self:request_flight(timestamp)
    end
    return 0
end

function FlightRuler:get_finish_exp(timestamp)
    local remain_time = self.__timestamp + FLIGHTVALID - timestamp
    local exp = math.floor(300 * (remain_time/FLIGHTVALID))
    return exp
end

function FlightRuler:flight_take_off(timestamp)
    self.__station_status = 4
    self.__timestamp = timestamp
    return 0
end

function FlightRuler:check_can_back_promote(timestamp)
    if self.__station_status == 3 then
        return self.__timestamp + FLIGHTVALID < timestamp and self.__timestamp + FLIGHTINTERVAL > timestamp
    elseif self.__station_status == 4 then
        return self.__timestamp + FLIGHTBACK > timestamp
    elseif self.__station_status == 5 then
        return self.__timestamp > timestamp
    end
end

function FlightRuler:get_back_remain_time(timestamp)
    if self.__station_status == 3 then
        return self.__timestamp + FLIGHTINTERVAL - timestamp
    elseif self.__station_status == 4 then
        return self.__timestamp + FLIGHTBACK - timestamp
    elseif self.__station_status == 5 then
        return self.__timestamp - timestamp
    end
end

function FlightRuler:promote_back(timestamp,cash_count)
    if not self:check_can_back_promote(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote
    end
    local remain_time = self:get_back_remain_time(timestamp)
    local cost_cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if cost_cash ~= cash_count then
        LOG_ERROR("cost_cash:%d cash_count:%d remain_time:%d err:%s",cost_cash,cash_count,remain_time,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    self.__role_object:consume_cash(cash_count,CONSUME_CODE.promote)
    self.__timestamp = timestamp
    self.__station_status = 3
    return 0
end

function FlightRuler:check_row_can_help(row)
    local order_object = self.__order_objects[row]
    if not order_object then return false end
    return order_object:check_can_help()
end

function FlightRuler:request_flight_help(timestamp,row,column)
    if self.__station_status ~= 3 then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    if self.__timestamp + FLIGHTVALID < timestamp then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    if not self:check_row_can_help(row) then 
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_help))
        return GAME_ERROR.cant_help
    end
    local order_box = self:get_order_box(row,column)
    if not order_box then
        LOG_ERROR("row:%d column:%d err:%s",row,column,errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.order_not_exist
    end
    if not order_box:check_can_request_help() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_help))
        return GAME_ERROR.cant_help
    end
    order_box:set_request_help()
    return 0
end

function FlightRuler:finish_flight_help(account_id,timestamp,row,column)
    if self.__station_status ~= 3 then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    if self.__timestamp + FLIGHTVALID < timestamp then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    local order_box = self:get_order_box(row,column)
    if not order_box then
        LOG_ERROR("row:%d column:%d err:%s",row,column,errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.order_not_exist
    end
    if not order_box:is_help() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    order_box:finish_order_help(account_id)
    local order_object = self.__order_objects[row]
    local count = self:get_finish_order_count()
    if order_object:check_order_finish() then
        local reward_object = self.__order_rewards[count]
        if not reward_object:check_can_receive() then
            LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_reward))
            return GAME_ERROR.cant_reward
        end
        reward_object:receive_reward()
    end
    if count == 3 then
        self.__role_object:get_daily_ruler():finish_flight()
        self.__role_object:get_achievement_ruler():finish_flight_record()
        local contine_count = self.__role_object:get_continue_flight_order() + 1
        self.__role_object:set_continue_flight_order(contine_count)
        local max_count = self.__role_object:get_max_continue_flight()
        if contine_count > max_count then
            self.__role_object:set_max_continue_flight(contine_count)
            self.__role_object:get_achievement_ruler():continue_flight(contine_count)
        end
        local exp = self:get_finish_exp(timestamp)
        self.__role_object:add_exp(exp,SOURCE_CODE.reward)
        self.__station_status = 4
        self.__timestamp = timestamp
        self:request_flight(timestamp)
    end
    local gold = order_box:get_order_value()
    local exp = order_box:get_order_exp()
    local friendly = order_box:get_friendly()
    self.__role_object:add_friendly(friendly,SOURCE_CODE.behelped)
    self.__role_object:send_request("finish_flight_help",{row=row,column=column,exp=exp,gold=gold,role_id=account_id})
    return 0,gold,exp,friendly
end

function FlightRuler:confirm_flight_help(timestamp,row,column)
    if self.__station_status ~= 3 then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    if self.__timestamp + FLIGHTVALID < timestamp then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    local order_box = self:get_order_box(row,column)
    if not order_box then
        LOG_ERROR("row:%d column:%d err:%s",row,column,errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.order_not_exist
    end
    order_box:confirm_flight_help()
    return 0
end

return FlightRuler