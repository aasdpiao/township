local class = require("class")

local RoleBase = class()

function RoleBase:ctor()
end

function RoleBase:get_account_id()
    return self.__account_id
end

function RoleBase:get_town_name()
    return self.__town_name
end

function RoleBase:set_town_name(town_name)
    self.__town_name = town_name
end

function RoleBase:set_avatar_index(avatar_index)
    self.__avatar_index = avatar_index
end

function RoleBase:get_avatar_index()
    return self.__avatar_index
end

function RoleBase:get_gold()
    return self.__gold
end

function RoleBase:get_cash()
    return self.__cash
end

function RoleBase:get_topaz()
    return self.__topaz
end

function RoleBase:get_emerald()
    return self.__emerald
end

function RoleBase:get_ruby()
    return self.__ruby
end

function RoleBase:get_amethyst()
    return self.__amethyst
end

function RoleBase:get_level()
    return self.__level
end

function RoleBase:set_level(level)
    self.__level = level
end

function RoleBase:check_level(level)
    return self.__level >= level
end

function RoleBase:get_exp()
    return self.__exp
end

function RoleBase:check_people(people)
    local current_people = self.__people_ruler:get_people()
    return current_people >= people
end

function RoleBase:check_enough_gold(money)
    return self.__gold >= money
end

function RoleBase:consume_gold(money,consume)
    self.__gold = self.__gold - money
    consume = consume or CONSUME_CODE.no_consume
    self:add_user_record("%s 消耗金币 %d",consume_msg(consume),money)
end

function RoleBase:add_gold(money,source)
    self.__gold = self.__gold + money
    source = source or SOURCE_CODE.no_source
    self:add_user_record("%s 增加金币 %d",source_msg(source),money)
    self:get_achievement_ruler():earn_gold_count(money)
end

function RoleBase:check_enough_cash(money)
    return self.__cash >= money
end

function RoleBase:consume_cash(money,consume)
    self.__cash = self.__cash - money
    consume = consume or CONSUME_CODE.no_consume
    self:add_user_record("%s 消耗钞票 %d",consume_msg(consume),money)
    self:get_daily_ruler():use_cash(money)
    if self.__level < 10 then
        self:statistics_consume_cash(money)
    end
end

function RoleBase:add_cash(money,source)
    self.__cash = self.__cash + money
    source = source or SOURCE_CODE.no_source
    self:add_user_record("%s 增加钞票 %d",source_msg(source),money)
end

function RoleBase:check_enough_topaz(money)
    return self.__topaz >= money
end

function RoleBase:consume_topaz(money,consume)
    self.__topaz = self.__topaz - money
    consume = consume or CONSUME_CODE.no_consume
    self:add_user_record("%s 消耗黄宝石 %d",consume_msg(consume),money)
    self:get_achievement_ruler():cost_gem(money)
end

function RoleBase:add_topaz(money,source)
    self.__topaz = self.__topaz + money
    source = source or SOURCE_CODE.no_source
    self:add_user_record("%s 增加黄宝石 %d",source_msg(source),money)
end

function RoleBase:check_enough_emerald(money)
    return self.__emerald >= money
end

function RoleBase:consume_emerald(money,consume)
    self.__emerald = self.__emerald - money
    consume = consume or CONSUME_CODE.no_consume
    self:add_user_record("%s 消耗绿宝石 %d",consume_msg(consume),money)
    self:get_achievement_ruler():cost_gem(money)
end

function RoleBase:add_emerald(money,source)
    self.__emerald = self.__emerald + money
    source = source or SOURCE_CODE.no_source
    self:add_user_record("%s 增加绿宝石 %d",source_msg(source),money)
end

function RoleBase:check_enough_ruby(money)
    return self.__ruby >= money
end

function RoleBase:consume_ruby(money,consume)
    self.__ruby = self.__ruby - money
    consume = consume or CONSUME_CODE.no_consume
    self:add_user_record("%s 消耗红宝石 %d",consume_msg(consume),money)
    self:get_achievement_ruler():cost_gem(money)
end

function RoleBase:add_ruby(money,source)
    self.__ruby = self.__ruby + money
    source = source or SOURCE_CODE.no_source
    self:add_user_record("%s 增加红宝石 %d",source_msg(source),money)
end

function RoleBase:check_enough_amethyst(money)
    return self.__amethyst >= money
end

function RoleBase:consume_amethyst(money,consume)
    self.__amethyst = self.__amethyst - money
    consume = consume or CONSUME_CODE.no_consume
    self:add_user_record("%s 消耗紫宝石 %d",consume_msg(consume),money)
    self:get_achievement_ruler():cost_gem(money)
end

function RoleBase:add_amethyst(money,source)
    self.__amethyst = self.__amethyst + money
    source = source or SOURCE_CODE.no_source
    self:add_user_record("%s 增加紫宝石 %d",source_msg(source),money)
end

function RoleBase:add_exp(exp,source)
    source = source or SOURCE_CODE.no_source
    self:add_user_record("%s 增加经验 %d",source_msg(source),exp)
    self:calc_role_exp(exp)
end

function RoleBase:calc_role_exp(exp)
    local role_entry = self.__role_manager:get_role_entry(self.__level)
    local max_exp = role_entry:get_max_exp()
    self.__exp = self.__exp + exp
    if self.__exp < max_exp then return end
    self.__level = self.__level + 1
    exp = self.__exp - max_exp
    self.__exp = 0
    self:do_levelup_after()
    return self:calc_role_exp(exp)
end

function RoleBase:do_levelup_after()
    self:pay_levelup_reward()
    self.__event_ruler:do_levelup_after()
    self.__daily_ruler:seven_levelup(self.__level)
end

function RoleBase:get_role_entry()
    return self.__role_manager:get_role_entry(self.__level)
end

function RoleBase:pay_levelup_reward()
    local role_entry = self:get_role_entry()
    local reward_gold = role_entry:get_reward_gold()
    local reward_cash = role_entry:get_reward_cash()
    local reward_item = role_entry:get_reward_item()
    self:add_gold(reward_gold,SOURCE_CODE.levelup)
    self:add_cash(reward_cash,SOURCE_CODE.levelup)
    for k,v in pairs(reward_item) do
        self:add_item(k,v,SOURCE_CODE.levelup)
    end
end
--[[
3001	黄宝石  topaz
3002	蓝宝石 emerald
3003	红宝石 ruby
3004	紫宝石 amethyst
7001	金币
7002	钞票
7003	好友值
]]
function RoleBase:add_item(item_index,item_count,source)
    if item_index == 7001 then
        self:add_gold(item_count,source)
    elseif item_index == 7002 then
        self:add_cash(item_count,source)
    elseif item_index == 7003 then
        self:add_friendly(item_count,source)
    elseif item_index == 3001 then
        self:add_topaz(item_count,source)
    elseif item_index == 3002 then
        self:add_emerald(item_count,source)
    elseif item_index == 3003 then
        self:add_ruby(item_count,source)
    elseif item_index == 3004 then
        self:add_amethyst(item_count,source)
    else
        self.__item_ruler:add_item_count(item_index,item_count)
        source = source or SOURCE_CODE.no_source
        local item_entry = self.__item_ruler:get_item_manager():get_item_entry(item_index)
        assert(item_entry,"item_entry is nil :"..item_index)
        local item_name = item_entry:get_item_name()
        self:add_user_record("%s 增加物品 %s %d",source_msg(source),item_name,item_count)
    end
end

function RoleBase:check_enough_item(item_index,item_count)
    item_count = item_count or 1
    return self.__item_ruler:check_enough_item_count(item_index,item_count)
end
--[[
3001	黄宝石  topaz
3002	蓝宝石 emerald
3003	红宝石 ruby
3004	紫宝石 amethyst
7001	金币
7002	钞票
7003	好友值
]]
function RoleBase:consume_item(item_index,item_count,consume)
    item_count = item_count or 1
    if item_index == 7001 then
        self:consume_gold(item_count,consume)
    elseif item_index == 7002 then
        self:consume_cash(item_count,consume)
    elseif item_index == 7003 then
        self:consume_friendly(item_count,consume)
    elseif item_index == 3001 then
        self:consume_topaz(item_count,consume)
    elseif item_index == 3002 then
        self:consume_emerald(item_count,consume)
    elseif item_index == 3003 then
        self:consume_ruby(item_count,consume)
    elseif item_index == 3004 then
        self:consume_amethyst(item_count,consume)
    else 
        self.__item_ruler:consume_item_count(item_index,item_count)
        consume = consume or CONSUME_CODE.no_consume
        local item_entry = self.__item_ruler:get_item_manager():get_item_entry(item_index)
        assert(item_entry,"item_entry is nil :"..item_index)
        local item_name = item_entry:get_item_name()
        self:add_user_record("%s 消耗物品 %s %d",consume_msg(consume),item_name,item_count)
    end
end

return RoleBase