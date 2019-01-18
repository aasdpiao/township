local class = require "class"
local FeedObject = require "feed.feed_object"
local FeedManager = require "feed.feed_manager"
local FeedDispatcher = require "feed.feed_dispatcher"
local packer = require "db.packer"

local FeedRuler = class()

function FeedRuler:ctor(role_object)
    self.__role_object = role_object
    self.__feed_objects = {}
end

function FeedRuler:init()
    self.__feed_manager = FeedManager.new()
    self.__feed_manager:init()

    self.__feed_dispatcher = FeedDispatcher.new(self.__role_object)
    self.__feed_dispatcher:init()
end

function FeedRuler:get_build_entry(build_index)
    return self.__role_object:get_grid_ruler():get_build_entry(build_index)
end

function FeedRuler:get_feed_entry(product_index)
    return self.__feed_manager:get_feed_entry(product_index)
end

function FeedRuler:load_feed_data(feed_data)
    if not feed_data then return end
    local code = packer.decode(feed_data)
    local feed_objects = code.feed_objects
    if not feed_objects then return end
    for k,v in pairs(feed_objects) do
        local build_id = v.build_id
        local feed_object = self.get_feed_object(self,build_id)
        feed_object:load_feed_object(v)
    end
end

function FeedRuler:dump_feed_data()
    local feed_data = {}
    feed_data.feed_objects = {}
    for build_id,feed_object in pairs(self.__feed_objects) do
        table.insert(feed_data.feed_objects,feed_object:dump_feed_object())
    end
    return feed_data
end

function FeedRuler:serialize_feed_data()
    local factory_data = self.dump_feed_data(self)
    return packer.encode(factory_data)
end

function FeedRuler:add_feed_object(build_id,build_index)
    local build_entry = self.get_build_entry(self,build_index)
    local feed_object = FeedObject.new(self.__role_object,build_id,build_entry)
    self.__feed_objects[build_id] = feed_object
end

function FeedRuler:get_feed_object(build_id)
    return self.__feed_objects[build_id]
end

return FeedRuler