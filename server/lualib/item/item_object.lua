local class = require "class"
local cjson = require "cjson"
local ItemObject = class()

function ItemObject:ctor(item_entry)
    self.__item_entry = item_entry
    self.__item_index = item_entry:get_item_index()
    self.__item_count = 1
end

function ItemObject:dump_item_object()
    local item_object = {}
    item_object.item_index = self.__item_index
    item_object.item_count = self.__item_count
    return item_object
end

function ItemObject:get_item_index()
    return self.__item_index
end

function ItemObject:get_item_count()
    return self.__item_count
end

function ItemObject:set_item_count(count)
    self.__item_count = count
end

function ItemObject:add_item_count(item_count)
    local count = self.get_item_count(self)
    self.set_item_count(self,count+item_count)
end

function ItemObject:debug_info()
    local item_info = ""
    item_info = item_info.."item_index:"..self.__item_index.."\n"
    item_info = item_info.."item_name:"..self.__item_entry:get_item_name().."\n"
    item_info = item_info.."item_count:"..self.__item_count.."\n"
    return item_info
end

return ItemObject