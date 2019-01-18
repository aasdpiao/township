local class = require "class"
local datacenter = require "skynet.datacenter"
local BusinessmanEntry = require "market.businessman_entry"
local ExpandEntry = require "market.expand_entry"
local SaleEntry = require "market.sale_entry"
local SaleObject = require "market.sale_object"
local utils = require "utils"

local MarketManager = class()

function MarketManager:ctor(role_object)
    self.__role_object = role_object

    self.__businessman_entrys = {}
    self.__expand_entrys = {}
    self.__sale_entrys = {}
end

function MarketManager:init()
    self:load_businessman_config()
    self:load_count_config()
    self:load_sale_config()
end

function MarketManager:load_businessman_config()
    local market_businessma_config = datacenter.get("businessman_config")
    for k,v in pairs(market_businessma_config) do
        local businessman_index = v.businessman_index
        local employ_time = v.employ_time
        local employ_cash = v.employ_cash
        local rest_time = v.rest_time
        local businessman_entry = BusinessmanEntry.new(businessman_index,employ_time,employ_cash,rest_time)
        self.__businessman_entrys[businessman_index] = businessman_entry
    end
end

function MarketManager:load_count_config()
    local market_count_config = datacenter.get("market_count_config")
    for k,v in pairs(market_count_config) do
        local index = v.index
        local unlock_cash = v.unlock_cash
        local expand_entry = ExpandEntry.new(index,unlock_cash)
        self.__expand_entrys[index] = expand_entry
    end
end

function MarketManager:load_sale_config()
    local market_order_config = datacenter.get("market_order_config")
    for k,v in pairs(market_order_config) do
        local sale_index = v.order_index
        local sale_entry = SaleEntry.new(v)
        self.__sale_entrys[sale_index] = sale_entry
    end
end

function MarketManager:get_businessman_entry(businessman_index)
    return self.__businessman_entrys[businessman_index]
end

function MarketManager:get_expand_entry(unlock_index)
    return self.__expand_entrys[unlock_index]
end

function MarketManager:get_sale_entry(sale_index)
    return self.__sale_entrys[sale_index]
end

function MarketManager:generate_sale_objects(count)
    local sale_objects = {}
    local level = self.__role_object:get_level()
    local sale_entrys = {}
    local total_weight = 0
    for k,v in pairs(self.__sale_entrys) do
        if v:check_level(level) then
            local sale_index = v:get_sale_index()
            local weight = v:get_sale_weight()
            table.insert( sale_entrys, {sale_index,weight})
            total_weight = total_weight + weight
        end
    end
    for i=1,count do
        local sale_index = utils.get_random_value_in_weight(total_weight,sale_entrys)
        local sale_entry = self:get_sale_entry(sale_index)
        local item_count = sale_entry:generate_count()
        local sale_object = SaleObject.new(self.__role_object,sale_entry,item_count)
        table.insert( sale_objects, sale_object )
    end
    return sale_objects
end

function MarketManager:generate_sale_object()
    local sale_objects = {}
    local level = self.__role_object:get_level()
    local sale_entrys = {}
    local total_weight = 0
    for k,v in pairs(self.__sale_entrys) do
        if v:check_level(level) then
            local sale_index = v:get_sale_index()
            local weight = v:get_sale_weight()
            table.insert( sale_entrys, {sale_index,weight})
            total_weight = total_weight + weight
        end
    end
    local sale_index = utils.get_random_value_in_weight(total_weight,sale_entrys)
    local sale_entry = self:get_sale_entry(sale_index)
    local item_count = sale_entry:generate_count()
    local sale_object = SaleObject.new(self.__role_object,sale_entry,item_count)
    return sale_object
end

return MarketManager