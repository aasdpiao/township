local class = require "class"
local trains_const = require "trains.trains_const"
local OrderObject = require "trains.order_object"
local RewardObject = require "trains.reward_object"

local TrainsObject = class()

local trains_status = {}
trains_status.default = 0
trains_status.standby = 1 --列車到站
trains_status.waitback = 2
trains_status.reward = 3

function TrainsObject:ctor(role_object,trains_entry)
    self.__role_object = role_object
    self.__trains_entry = trains_entry
    self.__timestamp = 0
    self.__unlock = trains_const.lock
    self.__status = 0
    self.__terminal_index = 0
    self.__trains_orders = {}
    self.__trains_rewards = {}
    self.__trains_index = trains_entry:get_trains_index()
end

function TrainsObject:load_trains_object(trains_object)
    self.__timestamp = trains_object.timestamp
    self.__unlock = trains_object.unlock
    self.__status = trains_object.status
    self.__terminal_index = trains_object.terminal_index
    local order_objects = trains_object.order_objects
    local reward_objects = trains_object.reward_objects
    for i,order_data in ipairs(order_objects) do
        local order_index = order_data.order_index
        local item_index = order_data.item_index
        local item_count = order_data.item_count
        local order_entry = self.__role_object:get_trains_ruler():get_order_entry(order_index)
        local order_object = OrderObject.new(self.__role_object,order_entry,item_index,item_count)
        order_object:load_order_object(order_data)
        self.__trains_orders[i] = order_object
    end
    for i,reward_data in ipairs(reward_objects) do
        local reward_index = reward_data.reward_index
        local reward_entry = self.__role_object:get_trains_ruler():get_reward_entry(reward_index)
        local reward_object = RewardObject.new(reward_entry)
        reward_object:load_reward_object(reward_data)
        self.__trains_rewards[i] = reward_object
    end
end

function TrainsObject:dump_trains_object()
    local trains_object = {}
    trains_object.timestamp = self.__timestamp
    trains_object.trains_index = self.__trains_entry:get_trains_index()
    trains_object.unlock = self.__unlock
    trains_object.status = self.__status
    trains_object.terminal_index = self.__terminal_index
    trains_object.order_objects = self:dump_order_objects()
    trains_object.reward_objects = self:dump_reward_objects()
    return trains_object
end

function TrainsObject:dump_order_objects()
    local order_objects = {}
    for i,order_object in ipairs(self.__trains_orders) do
        table.insert( order_objects, order_object:dump_order_object() )
    end
    return order_objects
end

function TrainsObject:dump_reward_objects()
    local reward_objects = {}
    for i,reward_object in ipairs(self.__trains_rewards) do
        table.insert( reward_objects, reward_object:dump_reward_object() )
    end
    return reward_objects
end

function TrainsObject:get_trains_unlock()
    return self.__unlock
end

function TrainsObject:check_can_unlock()
    if self.__unlock == trains_const.unlock then return false end
    local unlock_level = self.__trains_entry:get_unlock_level()
    local unlock_money = self.__trains_entry:get_unlock_money()
    if not self.__role_object:check_level(unlock_level) then return false end
    if not self.__role_object:check_enough_gold(unlock_money) then return false end
    return true
end

function TrainsObject:check_can_promote()
    return self.__status == trains_status.waitback
end

function TrainsObject:check_can_reward()
    return self.__status == trains_status.reward
end

function TrainsObject:check_can_help()
    for i,trains_order in ipairs(self.__trains_orders) do
        if trains_order:is_help() then return false end
    end
    return true
end

function TrainsObject:check_can_request_new_trains()
    for i,reward_object in ipairs(self.__trains_rewards) do
        if not reward_object:is_get_reward() then return false end
    end
    return true
end

function TrainsObject:flush_trains_status(timestamp)
    if self.__status == trains_status.waitback then
        if self.__timestamp <= timestamp then
            self.__status = trains_status.reward
        end 
    elseif self.__status == trains_status.standby then
        for i,trains_order in ipairs(self.__trains_orders) do
            if not trains_order:check_order_finish() then return end
        end
        self.__role_object:get_achievement_ruler():finish_trains_order()
        self.__role_object:get_achievement_ruler():finish_trains_record()
        self.__role_object:get_daily_ruler():finish_trains()
        self.__status = trains_status.waitback
        local terminal_entry = self.__role_object:get_trains_ruler():get_terminal_entry(self.__terminal_index)
        assert(terminal_entry)
        local travel_time = terminal_entry:get_travel_time()
        local accelerate = 1
        local worker_object = self.__role_object:get_trains_ruler():get_worker_object()
        if worker_object then
            accelerate = worker_object:get_accelerate() * 0.01 + 1
        end
        self.__timestamp = timestamp + math.floor(travel_time / accelerate)
    end
end

function TrainsObject:refresh_wait_time(employ,timestamp)
    if self.__status ~= trains_status.waitback then return end
    local worker_object = self.__role_object:get_trains_ruler():get_worker_object()
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

function TrainsObject:get_unlock_money()
    return self.__trains_entry:get_unlock_money()
end

function TrainsObject:unlock_trains_object()
    self.__unlock = trains_const.unlock
end

function TrainsObject:generate_trains_object()
    self.__status = trains_status.standby
    self.__trains_orders = {}
    self.__trains_rewards = {}
    self.__terminal_index = self.__role_object:get_trains_ruler():get_terminal_index()
    local trains_orders = self.__role_object:get_trains_ruler():get_trains_orders()
    local exp = self.__role_object:get_role_entry():get_trains_exp()
    local count = #trains_orders
    local order_exp = math.ceil(exp/count)
    for i,order_index in ipairs(trains_orders) do
        local order_entry = self.__role_object:get_trains_ruler():get_order_entry(order_index)
        local item_index = order_entry:get_item_index()
        local item_exp = order_entry:get_order_exp()
        local item_count = math.ceil(order_exp/item_exp)
        local order_object = OrderObject.new(self.__role_object,order_entry,item_index,item_count)
        self.__trains_orders[i] = order_object
    end
    local trains_rewards = self.__role_object:get_trains_ruler():get_trains_rewards(count)
    for i,reward_index in ipairs(trains_rewards) do
        local reward_entry = self.__role_object:get_trains_ruler():get_reward_entry(reward_index)
        local reward_object = RewardObject.new(reward_entry)
        self.__trains_rewards[i] = reward_object
    end
end

function TrainsObject:first_trains_object()
    self.__status = trains_status.standby
    self.__trains_orders = {}
    self.__trains_rewards = {}
    self.__terminal_index = self.__role_object:get_trains_ruler():get_terminal_index()
    local trains_orders = {[1001]= 5,[1016] = 2}
    for order_index,item_count in pairs(trains_orders) do
        local order_entry = self.__role_object:get_trains_ruler():get_order_entry(order_index)
        local item_index = order_entry:get_item_index()
        local order_object = OrderObject.new(self.__role_object,order_entry,item_index,item_count)
        table.insert(self.__trains_orders,order_object) 
    end
    local trains_rewards = self.__role_object:get_trains_ruler():get_trains_rewards(2)
    for i,reward_index in ipairs(trains_rewards) do
        local reward_entry = self.__role_object:get_trains_ruler():get_reward_entry(reward_index)
        local reward_object = RewardObject.new(reward_entry)
        self.__trains_rewards[i] = reward_object
    end
end

function TrainsObject:get_order_object(index)
    return self.__trains_orders[index]
end

function TrainsObject:get_reward_object(index)
    return self.__trains_rewards[index]
end

function TrainsObject:finish_trains_order(order_object)
    local order_index = order_object.order_index
    local item_index = order_object.item_index
    local item_count = order_object.item_count
    local order_object = self:get_order_object(order_index)
    if not order_object then
        LOG_ERROR("order_index:%d err:%s",order_index,errmsg(GAME_ERROR.order_not_exist))
        return GAME_ERROR.order_not_exist
    end
    if not order_object:check_can_finish() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    local order_item_index = order_object:get_item_index()
    if item_index ~= order_item_index then
        LOG_ERROR("item_index:%d order_item_index:%d err:%s",item_index,order_item_index,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    local order_item_count = order_object:get_item_count()
    if item_count ~= order_item_count then
        LOG_ERROR("item_count:%d order_item_count:%d err:%s",item_count,order_item_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end 
    if not self.__role_object:check_enough_item(item_index,item_count) then
        LOG_ERROR("item_index:%d item_count:%d err:%s",item_index,item_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.item_not_enough
    end
    local order_exp = order_object:get_order_exp()
    self.__role_object:add_exp(order_exp,SOURCE_CODE.finish)
    self.__role_object:consume_item(item_index,item_count,CONSUME_CODE.finish_order) 
    local account_id = self.__role_object:get_account_id()
    self.__role_object:publish("trains",account_id,account_id,self.__trains_index,order_index)
    order_object:finish_order_object()
    return 0
end

function TrainsObject:promote_trains(timestamp,cash_count)
    if not self:check_can_promote() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote
    end
    local terminal_entry = self.__role_object:get_trains_ruler():get_terminal_entry(self.__terminal_index)
    if not terminal_entry then 
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.terminal_not_exist))
        return GAME_ERROR.terminal_not_exist
    end
    local remain_time = self.__timestamp - timestamp 
    local cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if cash~= cash_count then
        LOG_ERROR("cash:%d cash_count:%d err:%s",cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    self.__role_object:consume_cash(cash,CONSUME_CODE.promote)
    self.__status = trains_status.reward
    return 0
end

function TrainsObject:get_trains_reward(reward_object)
    if not self:check_can_reward() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_reward))
        return GAME_ERROR.cant_reward
    end
    local reward_index = reward_object.reward_index
    local item_index = reward_object.item_index
    local item_count = reward_object.item_count
    local reward_object = self:get_reward_object(reward_index)
    if not reward_object then
        LOG_ERROR("reward_index:%d err:%s",reward_index,errmsg(GAME_ERROR.reward_not_exist))
        return GAME_ERROR.reward_not_exist
    end
    if not reward_object:check_can_reward() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_reward))
        return GAME_ERROR.cant_reward
    end
    local reward_item_index = reward_object:get_item_index()
    local reward_item_count = reward_object:get_item_count()
    if reward_item_index ~= item_index then
        LOG_ERROR("item_index:%d reward_item_index:%d err:%s",item_index,reward_item_index,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    if reward_item_count ~= item_count then
        LOG_ERROR("item_count:%d reward_item_count:%d err:%s",item_count,reward_item_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match
    end
    self.__role_object:add_item(item_index,item_count,SOURCE_CODE.reward)
    reward_object:finish_reward_object()
    return 0
end

function TrainsObject:request_order_help(order_object)
    if not self:check_can_help() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_help))
        return GAME_ERROR.cant_help
    end 
    local order_index = order_object.order_index
    local order_object = self:get_order_object(order_index)
    if not order_object then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.order_not_exist))
        return GAME_ERROR.order_not_exist
    end
    if not order_object:check_can_help() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_help))
        return GAME_ERROR.cant_help
    end
    order_object:set_is_help()
    return 0
end

function TrainsObject:request_new_trains(trains_index)
    if not self:check_can_request_new_trains() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_unlock))
        return GAME_ERROR.cant_unlock 
    end
    self:generate_trains_object()
    return 0
end

function TrainsObject:finish_trains_help(account_id,order_object)
    local order_index = order_object.order_index
    local order_object = self:get_order_object(order_index)
    if not order_object:is_help() then
        LOG_ERROR("order_index:%d,err:%s",order_index,errmsg(GAME_ERROR.cant_help))
        return GAME_ERROR.cant_help
    end
    order_object:finish_order_help()
    local exp = order_object:get_order_exp()
    local friendly = order_object:get_friendly()
    order_object:set_role_id(account_id)
    self.__role_object:add_friendly(friendly,SOURCE_CODE.behelped)
    self.__role_object:send_request("finish_trains_help",{role_id=account_id,trains_index=self.__trains_index,order_object={order_index=order_index}})
    self.__role_object:publish("trains",self.__role_object:get_account_id(),account_id,self.__trains_index,order_index)
    return 0,exp,friendly
end

function TrainsObject:confirm_friends_help(order_index)
    local order_object = self:get_order_object(order_index)
    if not order_object:check_can_finish_order_help() then
        LOG_ERROR("order_index:%d,err:%s",order_index,errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish
    end
    order_object:confirm_order_help()
    return 0
end

function TrainsObject:debug_info()
    local trains_info = ""
    trains_info = trains_info.."trains_index:"..self.__trains_entry:get_trains_index().."\n"
    trains_info = trains_info.."timestamp:"..self.__timestamp.."\n"
    trains_info = trains_info.."unlock:"..self.__unlock.."\n"
    trains_info = trains_info.."status:"..self.__status.."\n"
    trains_info = trains_info.."terminal_index:"..self.__terminal_index.."\n"
    local trains_orders_info = "\n"
    for k,trains_order in pairs(self.__trains_orders) do
        trains_orders_info = trains_orders_info..trains_order:debug_info()
    end
    local trains_rewards_info = "\n"
    for k,trains_reward in pairs(self.__trains_rewards) do
        trains_rewards_info = trains_rewards_info..trains_reward:debug_info()
    end
    trains_info = trains_info.."trains_orders:"..trains_orders_info.."\n"
    trains_info = trains_info.."trains_rewards:"..trains_rewards_info.."\n"
    return trains_info
end

return TrainsObject