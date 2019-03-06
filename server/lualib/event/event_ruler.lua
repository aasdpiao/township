
local class = require "class"
local EventManager = require "event.event_manager"
local EventDispatcher = require "event.event_dispatcher"
local EventObject = require "event.event_object"
local TaskObject = require "event.task_object"
local task_const = require "event.task_const"
local packer = require "db.packer"
local utils = require "utils"

local EventRuler = class()

local REFRESHTIME = 15 * 60
local PERSONS = {1001,1002,1003,1004,1005,1006,1007,1008,1009,1010}

function EventRuler:ctor(role_object)
    self.__role_object = role_object

    self.__event_objects = {}
    self.__event_seed = 0
    self.__timestamp = 0

    self.__task_objects = {}
    self.__type_task_objects = {}
    self.__task_index = 1001
end

function EventRuler:init()
    self.__event_manager = EventManager.new(self.__role_object)
    self.__event_manager:init()
    
    self.__event_dispatcher = EventDispatcher.new(self.__role_object)
    self.__event_dispatcher:init()

    self:init_task_objects()
end

function EventRuler:get_event_manager()
    return self.__event_manager
end

function EventRuler:get_event_id()
    self.__event_seed = self.__event_seed + 1
    return self.__event_seed
end

function EventRuler:init_task_objects()
    local task_entrys = self.__event_manager:get_task_entrys()
    for k,v in pairs(task_entrys) do
        local task_object = TaskObject.new(self.__role_object,v)
        local task_index = task_object:get_task_index()
        local task_type = task_object:get_task_type()
        self.__task_objects[task_index] = task_object
        if not self.__type_task_objects[task_type] then self.__type_task_objects[task_type] = {} end
        table.insert(self.__type_task_objects[task_type],task_object)
    end
end

function EventRuler:do_levelup_after()
    local event_upper = self.__event_manager:get_event_upper()
    local event_count = self:get_order_count()
    if event_upper > event_count and self.__timestamp == 0 then 
        self.__timestamp = self.__role_object:get_time_ruler():get_current_time() + REFRESHTIME
        self.__role_object:send_request("event_update",{timestamp = self.__timestamp})
    end

    local level = self.__role_object:get_level()
    if level == 3 then
        local task_objects = self:dump_task_objects()
        local task_index = self.__task_index
        self.__role_object:send_request("unlock_main_task",{task_objects = task_objects,task_index = task_index})
    end
end

function EventRuler:load_event_data(event_data)
    if not event_data then return end
    local code = packer.decode(event_data)
    self.__event_seed = code.event_seed or 0
    self.__timestamp = code.timestamp or 0
    local evnet_objects = code.evnet_objects or {}
    local task_objects = code.task_objects or {}
    self:load_event_objects(evnet_objects)
    self:load_task_objects(task_objects)
end

function EventRuler:load_task_objects(task_objects)
    for i,v in ipairs(task_objects) do
        local task_index = v.task_index
        local task_object = self:get_task_object(task_index)
        task_object:load_task_object(v)
    end
end

function EventRuler:load_event_objects(evnet_objects)
    for i,v in ipairs(evnet_objects) do
        local event_id = v.event_id
        local event_object = EventObject.new(self.__role_object,event_id)
        event_object:load_event_object(v)
        self.__event_objects[event_id] = event_object
    end
end

function EventRuler:serialize_event_data()
    local event_data = self.dump_event_data(self)
    return packer.encode(event_data)
end

function EventRuler:dump_event_data()
    local event_data = {}
    event_data.event_seed = self.__event_seed
    event_data.timestamp = self.__timestamp
    event_data.task_index = self.__task_index
    event_data.event_objects = self:dump_event_objects()
    event_data.task_objects = self:dump_task_objects()
    return event_data
end

function EventRuler:dump_task_objects()
    local task_objects = {}
    for k,v in pairs(self.__task_objects) do
        table.insert(task_objects,v:dump_task_object())
    end
    return task_objects
end

function EventRuler:get_task_object(task_index)
    return self.__task_objects[task_index]
end

function EventRuler:get_type_task_objects(task_type)
    return self.__type_task_objects[task_type] or {}
end

function EventRuler:dump_event_objects()
    local event_objects = {}
    for k,v in pairs(self.__event_objects) do
        table.insert(event_objects,v:dump_event_object())
    end
    return event_objects
end

function EventRuler:get_event_object(event_id)
    return self.__event_objects[event_id]
end

function EventRuler:get_next_refresh_timestamp()
    return self.__timestamp
end

function EventRuler:get_order_count()
    local count = 0
    for k,v in pairs(self.__event_objects) do
        count = count + 1
    end
    return count
end

function EventRuler:get_not_exits_person()
    local unuse_person = {}
    local seed = 0
    for i,v in ipairs(PERSONS) do
        unuse_person[v] = true
        seed = seed + 1
    end
    for k,v in pairs(self.__event_objects) do
        local person_index = v:get_person_index()
        unuse_person[person_index] = false
        seed = seed - 1
    end
    local select = utils.get_random_int(1,seed)
    for k,v in pairs(unuse_person) do
        if v then
            select = select - 1
            if select <= 0 then return k end
        end
    end
    return PERSONS[utils.get_random_int(1,#PERSONS)]
end

function EventRuler:generate_event_object()
    local person_index = self:get_not_exits_person()
    local event_id = self:get_event_id()
    local order_index = self.__event_manager:generate_order_index()
    local event_object = EventObject.new(self.__role_object,event_id)
    event_object:set_order_index(order_index)
    event_object:set_person_index(person_index)
    self.__event_objects[event_id] = event_object
end

function EventRuler:request_event(timestamp)
    if self.__timestamp > timestamp then
        LOG_ERROR("timestamp : %s error : %s",get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_create_event))
        return GAME_ERROR.cant_create_event 
    end
    local event_upper = self.__event_manager:get_event_upper()
    local event_count = self:get_order_count()
    if event_count >= event_upper then
        LOG_ERROR("timestamp : %s error : %s",get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_create_event))
        return GAME_ERROR.cant_create_event
    end
    self:generate_event_object()
    local next_timestamp = timestamp + REFRESHTIME
    self.__timestamp = next_timestamp
    if self:get_order_count() == event_upper then
        self.__timestamp = 0
    end
    return 0
end

function EventRuler:finish_event(timestamp,event_id)
    local event_object = self:get_event_object(event_id)
    if not event_object then
        LOG_ERROR("timestamp : %s error : %s",get_epoch_time(timestamp),errmsg(GAME_ERROR.event_not_exist))
        return GAME_ERROR.event_not_exist
    end
    local event_entry = event_object:get_event_entry()
    local item_index = event_entry:get_item_index()
    local item_count = event_entry:get_item_count()
    local order_exp = event_entry:get_order_exp()
    local order_gold = event_entry:get_order_gold()
    if not self.__role_object:check_enough_item(item_index,item_count) then
        LOG_ERROR("item_index:%d,item_count:%d err:%s",item_index,item_count,errmsg(GAME_ERROR.item_not_enough))
        return GAME_ERROR.item_not_enough
    end
    self.__role_object:consume_item(item_index,item_count,CONSUME_CODE.event)
    self.__role_object:add_gold(order_gold,SOURCE_CODE.finish)
    self.__role_object:add_exp(order_exp,SOURCE_CODE.finish)
    self.__role_object:get_daily_ruler():help_pedestrian()
    self:main_task_event()
    self:finish_event_object(timestamp,event_id)
    return 0
end

function EventRuler:finish_event_object(timestamp,event_id)
    local event_upper = self.__event_manager:get_event_upper()
    local event_count = self:get_order_count()
    if event_count == event_upper then
        self.__timestamp = timestamp + REFRESHTIME
    end
    self.__event_objects[event_id] = nil
end

function EventRuler:cancel_event(timestamp,event_id)
    local event_object = self:get_event_object(event_id)
    if not event_object then
        LOG_ERROR("timestamp : %s error : %s",get_epoch_time(timestamp),errmsg(GAME_ERROR.event_not_exist))
        return GAME_ERROR.event_not_exist
    end
    self:finish_event_object(timestamp,event_id)
    return 0
end

function EventRuler:finish_main_task(task_index)

end

function EventRuler:finsh_main_task_times(task_index,times)
    times = times or 1
    local task_object = self:get_task_object(task_index)
    if not task_object then return end
    task_object:finish_task_times(times)
    if task_object:check_task_finish() then
        self.__role_object:send_request("finish_main_task",{task_index=task_index})
    end
end

function EventRuler:refresh_main_task_times(task_index,times)
    times = times or 1
    local task_object = self:get_task_object(task_index)
    if not task_object then return end
    task_object:refresh_task_times(times)
end

function EventRuler:main_task_build(build_index)
    local task_objects = self:get_type_task_objects(task_const.build)
    for i,v in ipairs(task_objects) do
        local relate_index = v:get_relate_index()
        if relate_index == build_index then
            v:finsh_main_task_times()
        end
    end
end

function EventRuler:main_task_factory(item_index,item_count)
    local task_objects = self:get_type_task_objects(task_const.factory)
    for i,v in ipairs(task_objects) do
        local relate_index = v:get_relate_index()
        if relate_index == item_index then
            v:finsh_main_task_times(item_count)
        end
    end
end

function EventRuler:main_task_plant(item_index)
    local task_objects = self:get_type_task_objects(task_const.plant)
    for i,v in ipairs(task_objects) do
        local relate_index = v:get_relate_index()
        if relate_index == item_index then
            v:finsh_main_task_times()
        end
    end
end

function EventRuler:main_task_feed(item_index)
    local task_objects = self:get_type_task_objects(task_const.feed)
    for i,v in ipairs(task_objects) do
        local relate_index = v:get_relate_index()
        if relate_index == item_index then
            v:finsh_main_task_times()
        end
    end
end 

function EventRuler:main_task_helicopter()
    local task_objects = self:get_type_task_objects(task_const.helicopter)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times()
    end
end

function EventRuler:main_task_trains()
    local task_objects = self:get_type_task_objects(task_const.trains)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times()
    end
end

function EventRuler:main_task_undevelop(times)
    local task_objects = self:get_type_task_objects(task_const.undevelop)
    for i,v in ipairs(task_objects) do
        v:refresh_task_times(times)
    end
end

function EventRuler:main_task_event()
    local task_objects = self:get_type_task_objects(task_const.event)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times()
    end
end

function EventRuler:main_task_sale(times)
    local task_objects = self:get_type_task_objects(task_const.sale)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times(times)
    end
end

function EventRuler:main_task_invite()
    local task_objects = self:get_type_task_objects(task_const.invite)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times()
    end
end

function EventRuler:main_task_access()
    local task_objects = self:get_type_task_objects(task_const.access)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times()
    end
end

function EventRuler:main_task_thumb_up()
    local task_objects = self:get_type_task_objects(task_const.thumb_up)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times()
    end
end

function EventRuler:main_task_help_trains()
    local task_objects = self:get_type_task_objects(task_const.help_trains)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times()
    end
end

function EventRuler:main_task_help_water()
    local task_objects = self:get_type_task_objects(task_const.help_water)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times()
    end
end

function EventRuler:main_task_build_road()
    local task_objects = self:get_type_task_objects(task_const.build_road)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times()
    end
end

function EventRuler:main_task_head_icon()
    local task_objects = self:get_type_task_objects(task_const.head_icon)
    for i,v in ipairs(task_objects) do
        v:finsh_main_task_times()
    end
end

function EventRuler:main_task_upgrade_store(times)
    local task_objects = self:get_type_task_objects(task_const.upgrade_store)
    for i,v in ipairs(task_objects) do
        v:refresh_task_times(times)
    end
end

return EventRuler