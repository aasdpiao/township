local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"
local CMD = require "role.admin_power"

local RoleDispatcher = class()

function RoleDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function RoleDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function RoleDispatcher:register_s2c_callback(request_name,callback)
    self.__role_object:register_s2c_callback(request_name,callback)
end

function RoleDispatcher:init()
    self:register_c2s_callback("version_check",self.dispatcher_version_check)
    self:register_c2s_callback("cmd",self.dispatcher_cmd)
    self:register_c2s_callback("pull",self.dispatcher_pull)
    self:register_c2s_callback("buy_item",self.dispatcher_buy_item)
    self:register_c2s_callback("sale_item",self.dispatcher_sale_item)
    self:register_c2s_callback("sign_in",self.dispatcher_sign_in)
    self:register_c2s_callback("set_guide",self.dispatcher_set_guide)
    self:register_c2s_callback("add_item_capacity",self.dispatcher_add_item_capacity)
    self:register_c2s_callback("set_town_name",self.dispatcher_set_town_name)
    self:register_c2s_callback("set_avatar_index",self.dispatcher_set_avatar_index)
    self:register_c2s_callback("return_consume_cash",self.dispatcher_return_consume_cash)

    self:register_s2c_callback("send_mail",self.dispatcher_send_mail)
end

function RoleDispatcher.dispatcher_send_mail(role_object,args,msg_data)
    syslog.debug("dispatcher_send_mail",msg_data.result)
end

function RoleDispatcher.dispatcher_return_consume_cash(role_object,msg_data)
    local cash_count = msg_data.cash_count
    local consume_cash = role_object:get_consume_cash()
    if not role_object:check_can_return_consume() then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_return_consume))
        return {result = GAME_ERROR.cant_return_consume}
    end
    if consume_cash ~= cash_count then
        LOG_ERROR("cash_count:%d consume_cash = %d err:%s",cash_count,consume_cash,errmsg(GAME_ERROR.number_not_match))
        return {result = GAME_ERROR.number_not_match}
    end
    role_object:add_cash(cash_count,SOURCE_CODE.return_consume)
    role_object:set_return_consume_finish()
    return {result = 0}
end

function RoleDispatcher.dispatcher_set_town_name(role_object,msg_data)
    local town_name = msg_data.town_name
    role_object:set_town_name(town_name)
    return {result = 0}
end

function RoleDispatcher.dispatcher_set_avatar_index(role_object,msg_data)
    local avatar_index = msg_data.avatar_index
    role_object:set_avatar_index(avatar_index)
    return {result = 0}
end

function RoleDispatcher.dispatcher_add_item_capacity(role_object,msg_data)
    local expand_count = msg_data.expand_count
    local item_objects = msg_data.item_objects
    if not role_object:get_item_ruler():check_can_add_slot(expand_count) then
        LOG_ERROR("expand_count:%d err:%s",expand_count,errmsg(GAME_ERROR.cant_add_slot))
            return {result = GAME_ERROR.cant_add_slot}
    end
    local items = {}
    for i,v in ipairs(item_objects) do
        items[v.item_index] = v.item_count
    end
    local require_items = role_object:get_item_ruler():get_require_items()
    for k,v in pairs(require_items) do
        if v ~= items[k] then 
            LOG_ERROR("item_index:%d item_count:%d require_item_count:%d err:%s",k,items[k],v,errmsg(GAME_ERROR.number_not_match))
            return {result = GAME_ERROR.number_not_match}
        end
        if not role_object:check_enough_item(k,v) then
            LOG_ERROR("item_index:%d item_count:%d err:%s",k,v,errmsg(GAME_ERROR.item_not_enough))
            return {result = GAME_ERROR.item_not_enough}
        end
    end
    for k,v in pairs(require_items) do
        role_object:consume_item(k,v,CONSUME_CODE.add_slot)
    end
    role_object:get_item_ruler():set_expand_count(expand_count)
    return {result = 0}
end

function RoleDispatcher.dispatcher_set_guide(role_object,msg_data)
    local guide_index = msg_data.guide_index
    local progress = msg_data.progress
    role_object:set_guide(guide_index,progress)
    return {result = 0}
end

function RoleDispatcher.dispatcher_sign_in(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local continue_times = msg_data.continue_times
    local result = 0
    if not role_object:check_can_sign(timestamp) then
        LOG_ERROR("timestamp:%s continue_times:%d error:%s",get_epoch_time(timestamp),continue_times,errmsg(GAME_ERROR.cant_sign_in))
        result = GAME_ERROR.cant_sign_in
        return {result = result} 
    end
    local sign_in_times = role_object:get_continue_times(timestamp)
    if continue_times ~= sign_in_times then
        LOG_ERROR("timestamp:%s continue_times:%d sign_in_times:%d error:%s",get_epoch_time(timestamp),continue_times, sign_in_times, errmsg(GAME_ERROR.number_not_match))
        return {result = GAME_ERROR.number_not_match} 
    end
    local index = continue_times + 1
    role_object:set_continue_times(index)
    role_object:set_sign_timestamp(timestamp)
    local max_continue_times = role_object:get_max_continue_login()
    if index > max_continue_times then
        role_object:set_max_continue_login(index)
        role_object:get_achievement_ruler():continue_login(index)
    end
    if index < 5 then
        local item_index = 7001
        local item_count = role_object:get_role_manager():get_sign_gold(index)
        role_object:add_item(item_index,item_count,SOURCE_CODE.sign_in)
        return {result = 0,item_objects = {{item_index = item_index,item_count = item_count}}}
    else
        local item_objects = role_object:get_role_manager():gen_sign_rewards()
        for i,item_object in ipairs(item_objects) do
            local item_index = item_object.item_index
            local item_count = item_object.item_count
            role_object:add_item(item_index,item_count,SOURCE_CODE.sign_in)
        end
        return {result = 0,item_objects = item_objects}
    end
end

--版本检查
function RoleDispatcher.dispatcher_version_check(role_object,msg_data)
    local version = msg_data.version
    syslog.debug("version_check:",version)
    return {result = 0}
end

--GM指令
function RoleDispatcher.dispatcher_cmd(role_object,msg_data)
    local func = CMD[msg_data.cmd]
    local result = 0
    if func then
        result = func(role_object,msg_data.args)
    else
        syslog.err("cmd:"..msg_data.cmd.." not callback")
    end
    return {result = result}
end

--获取存档数据
function RoleDispatcher.dispatcher_pull(role_object,msg_data)
    local timestamp = role_object:get_time_ruler():get_current_time()
    role_object:get_event_ruler():request_event(timestamp)
    role_object:get_daily_ruler():refresh_daily(timestamp)
    role_object:refresh_kattle(timestamp)
    role_object:refresh_sign_in(timestamp)

    local account_id = role_object:get_account_id()
    local town_name = role_object:get_town_name()
    local gold = role_object:get_gold()
    local cash = role_object:get_cash()
    local topaz = role_object:get_topaz()
    local emerald = role_object:get_emerald()
    local ruby = role_object:get_ruby()
    local amethyst = role_object:get_amethyst()
    local level = role_object:get_level()
    local exp = role_object:get_exp()
    local thumb_up = role_object:get_thumb_up()
    local avatar_index = role_object:get_avatar_index()

    local role_attr = role_object:dump_role_attr()
    local item_data = role_object:get_item_ruler():dump_item_data()
    local grid_data = role_object:get_grid_ruler():dump_grid_data()
    local plant_data = role_object:get_plant_ruler():dump_plant_data()
    local factory_data = role_object:get_factory_ruler():dump_factory_data()
    local feed_data = role_object:get_feed_ruler():dump_feed_data()
    local trains_data = role_object:get_trains_ruler():dump_trains_data()
    local seaport_data = role_object:get_seaport_ruler():dump_seaport_data()
    local flight_data = role_object:get_flight_ruler():dump_flight_data()
    local helicopter_data = role_object:get_helicopter_ruler():dump_helicopter_data()
    local achievement_data = role_object:get_achievement_ruler():dump_achievement_data()
    local market_data = role_object:get_market_ruler():dump_market_data()
    local employment_data = role_object:get_employment_ruler():dump_employment_data()
    local mail_data = role_object:get_mail_ruler():dump_mail_data()
    local friend_data = role_object:get_friend_ruler():dump_friend_data()
    local event_data = role_object:get_event_ruler():dump_event_data()
    local daily_data = role_object:get_daily_ruler():dump_daily_data()
    
    local pull_data = {}
    pull_data.account_id = account_id
    pull_data.town_name = town_name
    pull_data.gold = gold
    pull_data.cash = cash
    pull_data.topaz = topaz
    pull_data.emerald = emerald
    pull_data.ruby = ruby
    pull_data.amethyst = amethyst
    pull_data.level = level
    pull_data.exp = exp
    pull_data.thumb_up = thumb_up
    pull_data.avatar_index = avatar_index

    pull_data.role_attr = role_attr
    pull_data.item_data = item_data
    pull_data.grid_data = grid_data
    pull_data.plant_data = plant_data
    pull_data.factory_data = factory_data
    pull_data.feed_data = feed_data
    pull_data.trains_data = trains_data
    pull_data.seaport_data = seaport_data
    pull_data.flight_data = flight_data
    pull_data.helicopter_data = helicopter_data
    pull_data.achievement_data = achievement_data
    pull_data.market_data = market_data
    pull_data.employment_data = employment_data
    pull_data.mail_data = mail_data
    pull_data.friend_data = friend_data
    pull_data.event_data = event_data
    pull_data.daily_data = daily_data
    return pull_data
end

function RoleDispatcher.dispatcher_buy_item(role_object,msg_data)
    local item_index = msg_data.item_index
    local item_count = msg_data.item_count
    local cash_count = msg_data.cash_count
    local item_ruler = role_object:get_item_ruler()
    local item_entry = item_ruler:get_item_entry(item_index)
    assert(item_entry,"item_entry is nil")
    local unit_price = item_entry:get_cash_count()
    local cash = unit_price * item_count
    if cash ~= cash_count then
        LOG_ERROR("item_index:%d item_count:%d cash_count:%d cash:%d error:%s",item_index,item_count,cash_count, cash, errmsg(GAME_ERROR.number_not_match))
        return {result = GAME_ERROR.number_not_match} 
    end
    if not role_object:check_enough_cash(cash) then
        LOG_ERROR("cash:%d error:%s", cash, errmsg(GAME_ERROR.cash_not_enough))
        return {result = GAME_ERROR.cash_not_enough} 
    end
    role_object:consume_cash(cash,CONSUME_CODE.buy_item)
    role_object:add_item(item_index,item_count,SOURCE_CODE.buy_item)
    return {result = 0}
end

function RoleDispatcher.dispatcher_sale_item(role_object,msg_data)
    local item_index = msg_data.item_index
    local item_count = msg_data.item_count
    local gold_count = msg_data.gold_count
    local item_ruler = role_object:get_item_ruler()
    local item_entry = item_ruler:get_item_entry(item_index)
    assert(item_entry,"item_entry is nil")
    local unit_price = item_entry:get_sale_price()
    local gold = unit_price * item_count
    if gold ~= gold_count then
        LOG_ERROR("item_index:%d item_count:%d gold_count:%d gold:%d error:%s",item_index,item_count,gold_count, gold, errmsg(GAME_ERROR.number_not_match))
        return {result = GAME_ERROR.number_not_match} 
    end
    if not role_object:check_enough_item(item_index,item_count) then
        LOG_ERROR("item_index:%d item_count:%d error:%s",item_index,item_count, errmsg(GAME_ERROR.number_not_match))
        return {result = GAME_ERROR.item_not_enough}
    end
    role_object:consume_item(item_index,item_count,CONSUME_CODE.sale_item)
    role_object:add_gold(gold,SOURCE_CODE.sale_item)
    local timestamp = skynet.call("timed","lua","query_current_time")
    role_object:get_achievement_ruler():limit_sale_barn(timestamp,gold)
    role_object:get_daily_ruler():sale_item(item_count)
    return {result = 0}
end

return RoleDispatcher

