local class = require "class"

local BuildEntry = class()

function BuildEntry:ctor(build_config)
    self.__build_index = build_config.build_index
    self.__build_attr = {}
    self.__unlock_entrys = {}
    self.__products = {}
    self.__slot_cost = {}
    
    for k,v in pairs(build_config) do
        self.__build_attr[k] = v
    end

    local build_property = build_config.build_property
    local property_values = build_config.property_values
    for k,v in pairs(build_property) do
        self.__build_attr[v] = property_values[k]
    end

    local product = build_config.product
    for i,v in ipairs(product) do
        self.__products[v] = true
    end

    local slot_cost = build_config.slot_cost
    local money_count = build_config.money_count

    for i,v in ipairs(slot_cost) do
        self.__slot_cost[v] = money_count[i]
    end

    self.__build_attr.build_property = nil
    self.__build_attr.property_values = nil
    self.__build_attr.product = nil
    self.__build_attr.slot_cost = nil
    self.__build_attr.money_count = nil
end

function BuildEntry:get_build_attr(key,default)
    return self.__build_attr[key] or default
end

function BuildEntry:add_unlock_entry(unlock_entry)
    local build_id = unlock_entry:get_build_id()
    self.__unlock_entrys[build_id] = unlock_entry
end

function BuildEntry:get_build_index()
    return self.__build_index
end

function BuildEntry:get_max_people()
    return self.get_build_attr(self,"max_people",0)
end

function BuildEntry:get_people()
    return self.get_build_attr(self,"people",0)
end

function BuildEntry:get_slot_count()
    return self.get_build_attr(self,"slot_count",0)
end

function BuildEntry:get_storage_count()
    return self.get_build_attr(self,"storage_count",6)
end

function BuildEntry:get_max_slot()
    return self.get_build_attr(self,"max_slot_count",0)
end

function BuildEntry:get_max_storage()
    return self.get_build_attr(self,"max_storage_count",6)
end

function BuildEntry:get_products()
    return self.__products
end

function BuildEntry:check_product_index(product_index)
    return self.__products[product_index]
end

function BuildEntry:get_slot_cost(slot_index)
    return self.__slot_cost[slot_index]  
end

function BuildEntry:get_profession_limit()
    return self.get_build_attr(self,"professional",0)
end

function BuildEntry:get_build_type()
    return self.get_build_attr(self,"build_type",0)
end

return BuildEntry