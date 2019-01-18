local BusinessmanObject = class()
local CommodityObject = require "market.commodity_object"

local RESTTIME = 1 * 60 * 60

function BusinessmanObject:ctor(role_object,businessman_index)
    self.__role_object = role_object
    self.__businessman_index = businessman_index
    self.__businessman_entry = role_object:get_market_ruler():get_businessman_entry(businessman_index)
    self.__timestamp = 0
    self.__expire_time = 0
    self.__commodity_objects = {}
end

function BusinessmanObject:dump_businessman_object()
    local businessman_object = {}
    businessman_object.businessman_index = self.__businessman_index
    businessman_object.timestamp = self.__timestamp
    businessman_object.expire_time = self.__expire_time
    businessman_object.commodity_objects = self:dump_commodity_objects()
    return businessman_object
end

function BusinessmanObject:load_businessman_object(timestamp,expire_time,commodity_objects)
    self.__timestamp = timestamp
    self.__expire_time = expire_time
    for i,v in ipairs(commodity_objects) do
        local sale_index = v.sale_index
        local item_count = v.item_count
        local commodity_object = CommodityObject.new(self.__role_object,sale_index,item_count)
        self.__commodity_objects[i]  = commodity_object
    end
end

function BusinessmanObject:set_buy_commodity(timestamp)
    self.__timestamp = timestamp
    self.__commodity_objects = {}
end

function BusinessmanObject:get_commodity_object(commodity_index)
    return self.__commodity_objects[commodity_index]
end

function BusinessmanObject:dump_commodity_objects()
    local commodity_objects = {}
    for i,v in ipairs(self.__commodity_objects) do
        commodity_objects[i] = v:dump_commodity_object()
    end
    return commodity_objects
end

function BusinessmanObject:set_employ_time(timestamp)
    self.__expire_time = timestamp + self.__businessman_entry:get_employ_time()
end

function BusinessmanObject:check_employ_expire(timestamp)
    return self.__expire_time >= timestamp
end

function BusinessmanObject:check_can_search(timestamp)
    return self.__timestamp + RESTTIME <= timestamp
end

function BusinessmanObject:set_commodity_counts(sale_entry)
    local commodity_counts = sale_entry:generate_employ_count()
    local sale_index = sale_entry:get_sale_index()
    for i=1,3 do
        local item_count = commodity_counts[i]
        local commodity_object = CommodityObject.new(self.__role_object,sale_index,item_count)
        self.__commodity_objects[i] = commodity_object
    end
end

return BusinessmanObject