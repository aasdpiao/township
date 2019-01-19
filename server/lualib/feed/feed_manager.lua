local calss = require "class"
local FeedEntry = require "feed.feed_entry"
local datacenter = require "skynet.datacenter"

local FeedManager = class()

function FeedManager:ctor()
    self.__feed_entrys = {}
end

function FeedManager:init()
    self:load_feed_config()
end

function FeedManager:load_feed_config()
    local product_breed = datacenter.get("product_breed")
    for k,v in pairs(product_breed) do
        local product_index = v.product_index
        local feed_entry = FeedEntry.new(v)
        self.__feed_entrys[product_index] = feed_entry
    end
end

function FeedManager:get_feed_entry(product_index)
    return self.__feed_entrys[product_index]
end

return FeedManager