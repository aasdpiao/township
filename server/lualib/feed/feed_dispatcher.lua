local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local FeedDispatcher = class()

function FeedDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function FeedDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function FeedDispatcher:init()
    self:register_c2s_callback("start_breed",self.dispatcher_start_breed)
    self:register_c2s_callback("harvest_breed",self.dispatcher_harvest_breed)
    self:register_c2s_callback("promote_breed",self.dispatcher_promote_breed)
    self:register_c2s_callback("add_breed_slot",self.dispatcher_add_breed_slot)
end

function FeedDispatcher.dispatcher_start_breed(role_object,msg_data)
    local build_id = msg_data.build_id
    local animal_objects = msg_data.animal_objects
    local feed_object = role_object:get_feed_ruler():get_feed_object(build_id)
    assert(feed_object,"feed_object:"..build_id.." is nil")
    for i,animal_object in ipairs(animal_objects) do
        local result = feed_object:start_breed(animal_object)
        if result > 0 then return {result = result} end
    end
    return {result = 0}
end

function FeedDispatcher.dispatcher_harvest_breed(role_object,msg_data)
    local build_id = msg_data.build_id
    local animal_objects = msg_data.animal_objects
    local feed_object = role_object:get_feed_ruler():get_feed_object(build_id)
    assert(feed_object,"feed_object:"..build_id.." is nil")
    for i,animal_object in ipairs(animal_objects) do
        local result = feed_object:harvest_breed(animal_object)
        if result > 0 then return {result = result} end
    end
    return {result = 0}
end

function FeedDispatcher.dispatcher_promote_breed(role_object,msg_data)
    local build_id = msg_data.build_id
    local animal_object = msg_data.animal_object
    local feed_object = role_object:get_feed_ruler():get_feed_object(build_id)
    assert(feed_object,"feed_object:"..build_id.." is nil")
    local result = feed_object:promote_breed(animal_object)
    return {result = result}
end

function FeedDispatcher.dispatcher_add_breed_slot(role_object,msg_data)
    local build_id = msg_data.build_id
    local gold_count = msg_data.gold_count
    local slot_index = msg_data.slot_index
    local feed_object = role_object:get_feed_ruler():get_feed_object(build_id)
    assert(feed_object,"feed_object:"..build_id.." is nil")
    local result = feed_object:add_breed_slot(slot_index,gold_count)
    return {result = result}
end

return FeedDispatcher

