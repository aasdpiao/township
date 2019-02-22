local class = require "class"
local skynet = require "skynet"
local RoleManager = require "role.role_manager"
local ItemRuler = require "item.item_ruler"
local GridRuler = require "grid.grid_ruler" 
local PlantRuler = require "plant.plant_ruler"
local FactoryRuler = require "factory.factory_ruler"
local FeedRuler = require "feed.feed_ruler"
local PeopleRuler = require "people.people_ruler"
local TimeRuler = require "time.time_ruler"
local TrainsRuler = require "trains.trains_ruler"
local SeaportRuler = require "seaport.seaport_ruler"
local FlightRuler = require "flight.flight_ruler"
local HelicopterRuler = require "helicopter.helicopter_ruler"
local AchievementRuler = require "achievement.achievement_ruler"
local MarketRuler = require "market.market_ruler"
local EmploymentRuler = require "employment.employment_ruler"
local MailRuler = require "mail.mail_ruler"
local FriendRuler = require "friend.friend_ruler"
local CacheRuler = require "cache.cache_ruler"
local EventRuler = require "event.event_ruler"
local DailyRuler = require "daily.daily_ruler"
local syslog = require "syslog"
local print_r = require "print_r"
local cjson = require "cjson"
local utils = require "utils"
local RoleBase = require "role.role_base"
local sprotoloader = require "sprotoloader"
local role_const = require "role.role_const"
local packer = require "db.packer"
local multicast = require "skynet.multicast"

local RoleObject = class(RoleBase)

local WEEKINTERVAL = 7 * 24 * 60 * 60
local DAYINTERVAL = 24 * 60 * 60

function RoleObject:ctor(account_id,username,send_request,publisher)
    self.__account_id = tonumber(account_id)
    self.__username = username
    self.__send_request = send_request
    self.__publisher = publisher

    self.__town_name = "township"
    self.__gold = 0
    self.__cash = 0
    
    self.__topaz = 0
    self.__emerald = 0
    self.__ruby = 0
    self.__amethyst = 0
    
    self.__level = 1
    self.__exp = 0

    self.__thumb_up = 0
    self.__avatar_index = 1

    self.__c2s_protocal = {}
    self.__s2c_protocal = {}

    self.__role_attrs = {}

    self.__offline = 0

    self.__dirty = false
end

function RoleObject:get_username()
    return self.__username
end

function RoleObject:get_account_id()
    return self.__account_id
end

function RoleObject:set_offline(status)
    self.__offline = status
    if status == 1 then
        self:unsubscribe()
    end
end

function RoleObject:init(offline)
    self.__role_manager = RoleManager.new(self)
    self.__role_manager:init()
    self.__item_ruler = ItemRuler.new(self)
    self.__item_ruler:init()
    self.__grid_ruler = GridRuler.new(self)
    self.__grid_ruler:init()
    self.__plant_ruler = PlantRuler.new(self)
    self.__plant_ruler:init()
    self.__factory_ruler = FactoryRuler.new(self)
    self.__factory_ruler:init()
    self.__feed_ruler = FeedRuler.new(self)
    self.__feed_ruler:init()
    self.__people_ruler = PeopleRuler.new(self)
    self.__people_ruler:init()
    self.__time_ruler = TimeRuler.new(self)
    self.__time_ruler:init()
    self.__trains_ruler = TrainsRuler.new(self)
    self.__trains_ruler:init()
    self.__seaport_ruler = SeaportRuler.new(self)
    self.__seaport_ruler:init()
    self.__flight_ruler = FlightRuler.new(self)
    self.__flight_ruler:init()
    self.__helicopter_ruler = HelicopterRuler.new(self)
    self.__helicopter_ruler:init()
    self.__achievement_ruler = AchievementRuler.new(self)
    self.__achievement_ruler:init()
    self.__market_ruler = MarketRuler.new(self)
    self.__market_ruler:init()
    self.__employment_ruler = EmploymentRuler.new(self)
    self.__employment_ruler:init()
    self.__mail_ruler = MailRuler.new(self)
    self.__mail_ruler:init()
    self.__friend_ruler = FriendRuler.new(self)
    self.__friend_ruler:init()
    self.__cache_ruler = CacheRuler.new(self)
    self.__cache_ruler:init()
    self.__event_ruler = EventRuler.new(self)
    self.__event_ruler:init()
    self.__daily_ruler = DailyRuler.new(self)
    self.__daily_ruler:init()

    self.__offline = offline
    self:load_player()
    self:load_role_default()
    self:load_mail()
end

function RoleObject:set_dirty(dirty)
    self.__dirty = dirty
end

function RoleObject:get_dirty()
    return self.__dirty
end

function RoleObject:set_init_finish()
    self.__role_attrs.init_finish = 1
end

function RoleObject:check_init_finish()
    return self.__role_attrs.init_finish == 1
end

function RoleObject:load_role_default()
    if self:check_init_finish() then return end
    local role_entry = self.__role_manager:get_role_entry(1)
    local reward_gold = role_entry:get_reward_gold()
    local reward_cash = role_entry:get_reward_cash()
    local reward_item = role_entry:get_reward_item()
    self.__gold = reward_gold
    self.__cash = reward_cash
    for item_index,item_count in pairs(reward_item) do
        self.__item_ruler:add_item_count(item_index,item_count)
    end
	local sql = string.format("call load_mail()")
    local ret = skynet.call("mysqld","lua","querygamedb",sql)
    local data = ret[1]
    self.__mail_ruler:load_init_mail(data)
    self:set_init_finish()
end

function RoleObject:register_c2s_callback(request_name,callback)
    self.__c2s_protocal[request_name] = callback
end

function RoleObject:register_s2c_callback(response_name,callback)
    self.__s2c_protocal[response_name] = callback
end

function RoleObject:get_handle_request(request_name)
    return self.__c2s_protocal[request_name]
end

function RoleObject:get_handle_response(response_name)
    return self.__s2c_protocal[response_name]
end

function RoleObject:get_role_manager()
    return self.__role_manager
end

function RoleObject:get_item_ruler()
    return self.__item_ruler
end

function RoleObject:get_plant_ruler()
    return self.__plant_ruler
end

function RoleObject:get_grid_ruler()
    return self.__grid_ruler
end

function RoleObject:get_time_ruler()
    return self.__time_ruler
end

function RoleObject:get_factory_ruler()
    return self.__factory_ruler
end

function RoleObject:get_feed_ruler()
    return self.__feed_ruler
end

function RoleObject:get_people_ruler()
    return self.__people_ruler
end

function RoleObject:get_trains_ruler()
    return self.__trains_ruler
end

function RoleObject:get_seaport_ruler()
    return self.__seaport_ruler
end

function RoleObject:get_flight_ruler()
    return self.__flight_ruler
end

function RoleObject:get_helicopter_ruler()
    return self.__helicopter_ruler
end

function RoleObject:get_achievement_ruler()
    return self.__achievement_ruler
end

function RoleObject:get_market_ruler()
    return self.__market_ruler
end

function RoleObject:get_employment_ruler()
    return self.__employment_ruler
end

function RoleObject:get_mail_ruler()
    return self.__mail_ruler
end

function RoleObject:get_friend_ruler()
    return self.__friend_ruler
end

function RoleObject:get_cache_ruler()
    return self.__cache_ruler
end

function RoleObject:get_event_ruler()
    return self.__event_ruler
end

function RoleObject:get_daily_ruler()
    return self.__daily_ruler
end

function RoleObject:get_role_attr(key,default)
    return self.__role_attrs[key] or default
end

function RoleObject:set_role_attr(key,value)
    self.__role_attrs[key] = value
end

function RoleObject:load_role_attr(role_attrs)
    if not role_attrs then return end
    self.__role_attrs = packer.decode(role_attrs)
end

function RoleObject:dump_role_attr()
    return packer.encode(self.__role_attrs)
end

function RoleObject:serialize_role_attr()
    return self:dump_role_attr()
end

function RoleObject:refresh_sign_in(timestamp)
    local sign_deadline = self.__role_attrs.sign_deadline or 0
    if timestamp >= sign_deadline then
        self.__role_attrs.sign_deadline = WEEKINTERVAL + timestamp
        self.__role_attrs.continue_times = 0
    end
end

function RoleObject:check_can_sign(timestamp)
    local sign_timestamp = self.__role_attrs.sign_timestamp or 0
    local interval_timestamp = utils.get_interval_timestamp(timestamp) - DAYINTERVAL
    return interval_timestamp > sign_timestamp
end

function RoleObject:get_continue_times(timestamp)
    self:refresh_sign_in(timestamp)
    local continue_times = self.__role_attrs.continue_times or 0
    return continue_times
end

function RoleObject:set_continue_times(times)
    self.__role_attrs.continue_times = times
end

function RoleObject:set_sign_timestamp(timestamp)
    self.__role_attrs.sign_timestamp = timestamp
end

function RoleObject:get_friendly()
    return self.__role_attrs.friendly or 0
end

function RoleObject:set_friendly(friendly)
    self.__role_attrs.friendly = friendly
end

function RoleObject:check_enough_friendly(friendly)
    local cur_friendly = self:get_friendly()
    return cur_friendly >= friendly
end

function RoleObject:consume_friendly(friendly,consume)
    local cur_friendly = self:get_friendly()
    self:set_friendly(cur_friendly - friendly)
    consume = consume or CONSUME_CODE.no_consume
    self:add_user_record("%s 消耗好友值 %d",consume_msg(consume),friendly)
end

function RoleObject:add_friendly(friendly,source)
    local cur_friendly = self:get_friendly()
    self:set_friendly(cur_friendly + friendly)
    source = source or SOURCE_CODE.no_source
    self:add_user_record("%s 增加好友值 %d",source_msg(source),friendly)
end

function RoleObject:statistics_consume_cash(cash)
    local consume_cash = self.__role_attrs.consume_cash or 0
    self.__role_attrs.consume_cash = consume_cash + cash
end

function RoleObject:get_consume_cash()
    return self.__role_attrs.consume_cash or 0
end

function RoleObject:set_return_consume_finish()
    self.__role_attrs.return_consume = 1
end

function RoleObject:check_can_return_consume()
    if self.__level < 10 then return false end
    return self.__role_attrs.return_consume ~= 1
end

function RoleObject:get_kettle_timestamp()
    return self.__role_attrs.kettle_timestamp or 0
end

function RoleObject:set_kettle_timestamp(timestamp)
    self.__role_attrs.kettle_timestamp = timestamp
end

function RoleObject:get_kettle_times()
    return self.__role_attrs.kettle_times or 0
end

function RoleObject:set_kettle_times(times)
    self.__role_attrs.kettle_times = times
end

function RoleObject:refresh_kattle(timestamp)
    if self:get_kettle_timestamp() > timestamp then return end
    local interval_timestamp = utils.get_interval_timestamp(timestamp)
    self:set_kettle_times(5)
    self:set_kettle_timestamp(interval_timestamp)
end

function RoleObject:check_can_watering()
    return self:get_kettle_times() > 0
end

function RoleObject:consume_kettle_times()
    local times = self:get_kettle_times()
    self:set_kettle_times(times - 1)
end

--成就 连续登陆天数
function RoleObject:get_max_continue_login()
    return self.__role_attrs.max_continue_login or 0
end

function RoleObject:set_max_continue_login(max_count)
    self.__role_attrs.max_count = max_count
end

--成就 连续完成飞机订单次数
function RoleObject:get_continue_flight_order()
    return self.__role_attrs.continue_flight_order or 0
end

function RoleObject:set_continue_flight_order(count)
    self.__role_attrs.continue_flight_order = count
end
--成就 连续完成飞机订单最大次数
function RoleObject:get_max_continue_flight()
    return self.__role_attrs.max_continue_flight or 0
end

function RoleObject:set_max_continue_flight(count)
    self.__role_attrs.max_continue_flight = count
end
--新手引导
function RoleObject:set_guide(index,progress)
    if not self.__role_attrs.guide then self.__role_attrs.guide = {} end
    self.__role_attrs.guide[index] = progress
end

function RoleObject:load_player()
    local player = skynet.call("redisd","lua","get_player",self.__account_id)
    if not player then return end
    local town_name = player.town_name
    local gold = player.gold
    local cash = player.cash
    local topaz = player.topaz
    local emerald = player.emerald
    local ruby = player.ruby
    local amethyst = player.amethyst
    local level = player.level
    local exp = player.exp
    local thumb_up = player.thumb_up
    local avatar_index = player.avatar_index

    local role_attr = player.role_attr
    local item_data = player.item_data
    local grid_data = player.grid_data
    local plant_data = player.plant_data
    local factory_data = player.factory_data
    local feed_data = player.feed_data
    local trains_data = player.trains_data
    local seaport_data = player.seaport_data
    local flight_data = player.flight_data
    local helicopter_data = player.helicopter_data
    local achievement_data = player.achievement_data
    local market_data = player.market_data
    local employment_data = player.employment_data
    local mail_data = player.mail_data
    local friend_data = player.friend_data
    local event_data = player.event_data
    local daily_data = player.daily_data
    if self.__offline == 1 then
        syslog.debug("offline load account_id:",self.__account_id)
    end
    self.__town_name = town_name
    self.__gold = gold
    self.__cash = cash
    self.__topaz = topaz
    self.__emerald = emerald
    self.__ruby = ruby
    self.__amethyst = amethyst
    self.__level = level
    self.__exp = exp
    self.__thumb_up = thumb_up
    self.__avatar_index = avatar_index

    self:load_role_attr(role_attr)
    self.__item_ruler:load_item_data(item_data)
    self.__grid_ruler:load_grid_data(grid_data)
    self.__plant_ruler:load_plant_data(plant_data)
    self.__factory_ruler:load_factory_data(factory_data)
    self.__feed_ruler:load_feed_data(feed_data)
    self.__trains_ruler:load_trains_data(trains_data)
    self.__seaport_ruler:load_seaport_data(seaport_data)
    self.__flight_ruler:load_flight_data(flight_data)
    self.__helicopter_ruler:load_helicopter_data(helicopter_data)
    self.__achievement_ruler:load_achievement_data(achievement_data)
    self.__market_ruler:load_market_data(market_data)
    self.__employment_ruler:load_employment_data(employment_data)
    self.__mail_ruler:load_mail_data(mail_data)
    self.__friend_ruler:load_friend_data(friend_data)
    self.__event_ruler:load_event_data(event_data)
    self.__daily_ruler:load_daily_data(daily_data)
end

function RoleObject:load_mail()
    local mysqld = skynet.queryservice("mysqld")
	local sql = string.format("call load_mail()")
    local ret = skynet.call(mysqld,"lua","querygamedb",sql)
    local data = ret[1]
    self.__mail_ruler:load_golabl_mail(data)
end

function RoleObject:get_thumb_up()
    return skynet.call("redisd","lua","get_thumb_up",self.__account_id)
end

function RoleObject:save_player()
    if not self.__dirty then return end
    self.__dirty = false
    local town_name = self.__town_name
    local gold = self.__gold
    local cash = self.__cash
    local topaz = self.__topaz
    local emerald = self.__emerald
    local ruby = self.__ruby
    local amethyst = self.__amethyst
    local level = self.__level
    local exp = self.__exp
    local thumb_up = self:get_thumb_up()
    local avatar_index = self.__avatar_index

    local role_attr = self.serialize_role_attr(self)
    local item_data = self.__item_ruler:serialize_item_data()
    local grid_data = self.__grid_ruler:serialize_grid_data()
    local plant_data = self.__plant_ruler:serialize_plant_data()
    local factory_data = self.__factory_ruler:serialize_factory_data()
    local feed_data = self.__feed_ruler:serialize_feed_data()
    local trains_data = self.__trains_ruler:serialize_trains_data()
    local seaport_data = self.__seaport_ruler:serialize_seaport_data()
    local flight_data = self.__flight_ruler:serialize_flight_data()
    local helicopter_data = self.__helicopter_ruler:serialize_helicopter_data()
    local achievement_data = self.__achievement_ruler:serialize_achievement_data()
    local market_data = self.__market_ruler:serialize_market_data()
    local employment_data = self.__employment_ruler:serialize_employment_data()
    local mail_data = self.__mail_ruler:serialize_mail_data()
    local friend_data = self.__friend_ruler:serialize_friend_data()
    local event_data = self.__event_ruler:serialize_event_data()
    local daily_data = self.__daily_ruler:serialize_daily_data()
    
    local player = {}
    player.town_name = town_name
    player.gold = gold
    player.cash = cash
    player.topaz = topaz
    player.emerald = emerald
    player.ruby = ruby
    player.amethyst = amethyst
    player.level = level
    player.exp = exp
    player.thumb_up = thumb_up
    player.avatar_index = avatar_index

    player.role_attr = role_attr
    player.item_data = item_data
    player.grid_data = grid_data
    player.plant_data = plant_data
    player.factory_data = factory_data
    player.feed_data = feed_data
    player.trains_data = trains_data
    player.seaport_data = seaport_data
    player.flight_data = flight_data
    player.helicopter_data = helicopter_data
    player.achievement_data = achievement_data
    player.market_data = market_data
    player.employment_data = employment_data
    player.mail_data = mail_data
    player.friend_data = friend_data
    player.event_data = event_data
    player.daily_data = daily_data

    skynet.call("redisd","lua","save_player",self.__account_id, player)
end

function RoleObject:get_http_statistics()
    local role_data = {}
    role_data.town_name = self.__town_name
    role_data.gold = self.__gold
    role_data.cash = self.__cash
    role_data.topaz = self.__topaz
    role_data.emerald = self.__emerald
    role_data.ruby = self.__ruby
    role_data.amethyst = self.__amethyst
    role_data.level = self.__level
    role_data.exp = self.__exp
    return role_data
end

function RoleObject:get_http_helicopter()
    return self.__helicopter_ruler:dump_helicopter_data()
end

function RoleObject:get_http_trains()
    return self.__trains_ruler:dump_trains_data()
end

function RoleObject:get_http_achievement()
    return self.__achievement_ruler:dump_achievement_data()
end

function RoleObject:get_http_market()
    return self.__market_ruler:dump_market_data()
end

function RoleObject:get_http_grid()
    return self.__grid_ruler:dump_grid_data()
end

function RoleObject:get_http_employment()
    return self.__employment_ruler:dump_employment_data()
end

function RoleObject:send_mail(mail_data)
    self.__mail_ruler:send_mail(mail_data)
end

function RoleObject:add_user_record(fmt, ...)
    syslog.debugf("account_id:%d "..fmt,self.__account_id,...)
    LOG_INFO("account_id:%d "..fmt,self.__account_id,...)
end

function RoleObject:send_request(name,args)
    if self.__offline == 1 then return end
    self.__send_request(name,args)
end

function RoleObject:publish(...)
    self.__publisher:publish(...)
end

function RoleObject:get_subscribe_channel()
    return self.__publisher.channel
end

function RoleObject:subscribe(account_id,channel)
    if self.__publish_id == account_id then return end
    if self.__subscribe then
	    self.__subscribe:unsubscribe()
    end
    self.__subscribe = multicast.new {
		channel = channel ,
        dispatch = function(channel, source, help_type, ...)
            if help_type == "trains" then
                self:subscribe_trains(...)
            elseif help_type == "flight" then
                self:subscribe_flight(...)
            elseif help_type == "plant" then
                self:subscribe_plant(...)
            end
        end,
    }
    self.__publish_id = account_id
    self.__subscribe:subscribe()
end

function RoleObject:unsubscribe()
    if not self.__subscribe then return end
    self.__subscribe:unsubscribe()
    self.__subscribe = nil
    self.__publish_id = nil
end

function RoleObject:subscribe_plant(plant_type,...)
    if plant_type == "watering" then
        local subscribe_role_id,help_role_id,build_id = table.unpack({...})
        self:send_request("subscribe_watering",{
            subscribe_role_id = subscribe_role_id,
            help_role_id = help_role_id,
            build_id = build_id,
        })
    elseif plant_type == "plant" then
        local subscribe_role_id,build_id,plant_index,harvest_time = table.unpack({...})
        self:send_request("subscribe_plant",{
            subscribe_role_id = subscribe_role_id,
            build_id = build_id,
            plant_index = plant_index,
            harvest_time = harvest_time,
        })
    elseif plant_type == "promote" then
        local subscribe_role_id,build_id = table.unpack({...})
        self:send_request("subscribe_promote",{
            subscribe_role_id = subscribe_role_id,
            build_id = build_id,
        })
    elseif plant_type == "harvest" then
        local subscribe_role_id,build_id = table.unpack({...})
        self:send_request("subscribe_harvest",{
            subscribe_role_id = subscribe_role_id,
            build_id = build_id,
        })
    end
end

function RoleObject:subscribe_trains(subscribe_role_id,help_role_id,trains_index,order_index)
    self:send_request("subscribe_trains_help",{
        subscribe_role_id = subscribe_role_id,
        help_role_id = help_role_id,
        trains_index = trains_index,
        order_index = order_index,
    })
end

function RoleObject:subscribe_flight(subscribe_role_id,help_role_id,row,column)
    self:send_request("subscribe_flight_help",{
        subscribe_role_id = subscribe_role_id,
        help_role_id = help_role_id,
        row = row,
        column = column,
    })
end

function RoleObject:debug_info()
    local role_info = ""
    role_info = role_info.."account_id:"..self.__account_id.."\n"
    role_info = role_info.."town_name:"..self.__town_name.."\n"
    role_info = role_info.."gold:"..self.__gold.."\n"
    role_info = role_info.."cash:"..self.__cash.."\n"
    role_info = role_info.."topaz:"..self.__topaz.."\n"
    role_info = role_info.."emerald:"..self.__emerald.."\n"
    role_info = role_info.."ruby:"..self.__ruby.."\n"
    role_info = role_info.."amethyst:"..self.__amethyst.."\n"
    role_info = role_info.."level:"..self.__level.."\n"
    role_info = role_info.."exp:"..self.__exp.."\n"
    role_info = role_info.."thumb_up:"..self.__thumb_up.."\n"
    role_info = role_info.."avatar_index:"..self.__avatar_index.."\n"
    role_info = role_info.."role_attr:"..cjson.encode(self.__role_attrs).."\n"

    role_info = role_info.."item:\n"..self.__item_ruler:debug_info().."\n"
    role_info = role_info.."factory:\n"..self.__factory_ruler:debug_info().."\n"
    role_info = role_info.."trains:\n"..self.__trains_ruler:debug_info().."\n"
    role_info = role_info.."employ:\n"..self.__employment_ruler:debug_info().."\n"
    return role_info
end

return RoleObject