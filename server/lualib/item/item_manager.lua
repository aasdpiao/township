local class = require "class"
local ItemEntry = require "item.item_entry"
local ExpandEntry = require "item.expand_entry"
local print_r = require "print_r"
local datacenter = require "skynet.datacenter"

local ItemManager = class()

function ItemManager:ctor()
    self.__item_entrys = {}
    self.__expand_entrys = {}
end

function ItemManager:init()
    self:load_item_config()
    self:load_barn_config()
end

function ItemManager:load_barn_config()
    local barn_config = datacenter.get("barn_config")
    for k,v in pairs(barn_config) do
        local barn_level = v.barn_level
        local expand_entry = ExpandEntry.new(barn_level,v)
        self.__expand_entrys[barn_level] = expand_entry
    end
end

function ItemManager:get_expand_entry(expand_count)
    return self.__expand_entrys[expand_count]
end

function ItemManager:load_item_config()
    local item_config = datacenter.get("item_config")
    for k,v in pairs(item_config) do
        local item_index = v.item_index
        local item_entry = ItemEntry.new(item_index)
        item_entry:init_item_entry(v)
        self.__item_entrys[item_index] = item_entry
    end
end

function ItemManager:get_item_entry(item_index)
    return self.__item_entrys[item_index]
end

return ItemManager