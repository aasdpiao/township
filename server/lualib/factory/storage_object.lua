local class = require "class"
local utils = require "utils"
local StorageObject = class()

function StorageObject:ctor(timestamp,product_index,slot_index,multiple)
    self.__timestamp = timestamp
    self.__product_index = product_index
    self.__slot_index = slot_index
    self.__multiple = multiple or 0
end

function StorageObject:get_tiemstamp()
    return self.__timestamp
end

function StorageObject:get_product_index()
    return self.__product_index
end

function StorageObject:get_slot_index()
    return self.__slot_index
end

function StorageObject:get_multiple()
    return self.__multiple
end

function StorageObject:dump_storage_object()
    local data = {}
    data.timestamp = self.__timestamp
    data.product_index = self.__product_index
    data.slot_index = self.__slot_index
    data.multiple = self.__multiple
    return data
end

function StorageObject:debug_info()
    local storage_info = ""
    storage_info = storage_info.."timestamp:"..utils.get_epoch_time(self.__timestamp).."\n"
    storage_info = storage_info.."product_index:"..self.__product_index.."\n"
    storage_info = storage_info.."slot_index:"..self.__slot_index.."\n"
    return storage_info
end

return StorageObject