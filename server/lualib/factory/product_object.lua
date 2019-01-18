local class = require "class"
local utils = require "utils"
local factory_const = require "factory.factory_const"

local ProductObject = class()

function ProductObject:ctor(role_object,product_time,timestamp,product_index)
    self.__role_object = role_object
    self.__timestamp = timestamp
    self.__product_time = product_time
    self.__product_index = product_index
    self.__status = factory_const.default
    local product_entry = role_object:get_factory_ruler():get_product_entry(product_index)
    self.__finish_time = product_entry:get_finish_time()
    self.__harvest_time = 0
    self.__multiple = 0
end

function ProductObject:set_status(status)
    self.__status = status
end

function ProductObject:get_status()
    return self.__status
end

function ProductObject:get_multiple()
    return self.__multiple
end

function ProductObject:set_multiple(multiple)
    self.__multiple = multiple
end

function ProductObject:set_product_time(product_time)
    self.__product_time = product_time
end

function ProductObject:get_product_time()
    return self.__product_time
end

function ProductObject:get_tiemstamp()
    return self.__timestamp
end

function ProductObject:get_finish_time()
    return self.__finish_time
end

function ProductObject:get_product_index()
    return self.__product_index
end

function ProductObject:get_harvest_time()
    return self.__harvest_time
end

function ProductObject:set_harvest_time(harvest_time)
    self.__harvest_time = harvest_time
end

function ProductObject:check_finish(timestamp)
    if self.__status == factory_const.promote then return true end
    return timestamp >= self.__harvest_time
end

function ProductObject:dump_product_object()
    local data = {}
    data.timestamp = self.__timestamp
    data.product_time = self.__product_time
    data.product_index = self.__product_index
    data.harvest_time = self.__harvest_time
    data.multiple = self.__multiple
    data.status = self.__status
    return data
end

function ProductObject:set_pause()
    self.__status = factory_const.pause
end

function ProductObject:start_product()
    self.__status = factory_const.default
end

function ProductObject:check_pause()
    return factory_const.pause == self.__status
end

function ProductObject:check_can_promote()
    return factory_const.pause ~= self.__status 
end

function ProductObject:debug_info()
    local product_info = ""
    product_info = product_info.."timestamp:"..utils.get_epoch_time(self.__timestamp).."\n"
    product_info = product_info.."product_time:"..utils.get_epoch_time(self.__product_time).."\n"
    product_info = product_info.."harvest_time:"..utils.get_epoch_time(self.__harvest_time).."\n"
    product_info = product_info.."product_index:"..self.__product_index.."\n"
    product_info = product_info.."status:"..self.__status.."\n"
    return product_info
end

return ProductObject