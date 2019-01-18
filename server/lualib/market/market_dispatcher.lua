local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local MarketDispatcher = class()

function MarketDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function MarketDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function MarketDispatcher:init()
    self:register_c2s_callback("unlock_market",self.dispatcher_unlock_market)
    self:register_c2s_callback("request_market",self.dispatcher_request_market)
    self:register_c2s_callback("refresh_market",self.dispatcher_refresh_market)
    self:register_c2s_callback("buy_sale",self.dispatcher_buy_sale)
    self:register_c2s_callback("employ_businessman",self.dispatcher_employ_businessman)
    self:register_c2s_callback("search_commodity",self.dispatcher_search_commodity)
    self:register_c2s_callback("buy_commodity",self.dispatcher_buy_commodity)
    self:register_c2s_callback("add_market_slot",self.dispatcher_add_market_slot)
end

function MarketDispatcher.dispatcher_add_market_slot(role_object,msg_data)
    local slot_index = msg_data.slot_index
    local cash_count = msg_data.cash_count
    local market_ruler = role_object:get_market_ruler()
    local result = market_ruler:add_market_slot(slot_index,cash_count)
    local sale_objects = market_ruler:dump_sale_objects()
    local refresh_timestamp = market_ruler:get_refresh_timestamp()
    return {result = result,sale_objects = sale_objects,timestamp=refresh_timestamp}
end

function MarketDispatcher.dispatcher_unlock_market(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local market_ruler = role_object:get_market_ruler()
    local result = market_ruler:unlock_market(timestamp)
    local sale_objects = market_ruler:dump_sale_objects()
    local refresh_timestamp = market_ruler:get_refresh_timestamp()
    return {result = result,sale_objects = sale_objects,timestamp=refresh_timestamp}
end

function MarketDispatcher.dispatcher_request_market(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local market_ruler = role_object:get_market_ruler()
    local result = market_ruler:request_market(timestamp)
    local sale_objects = market_ruler:dump_sale_objects()
    local refresh_timestamp = market_ruler:get_refresh_timestamp()
    return {result = result,sale_objects = sale_objects,timestamp=refresh_timestamp}
end

function MarketDispatcher.dispatcher_refresh_market(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local cash_count = msg_data.cash_count
    local market_ruler = role_object:get_market_ruler()
    local result = market_ruler:refresh_market(timestamp,cash_count)
    local sale_objects = market_ruler:dump_sale_objects()
    local refresh_timestamp = market_ruler:get_refresh_timestamp()
    return {result = result,sale_objects = sale_objects,timestamp=refresh_timestamp}
end

function MarketDispatcher.dispatcher_buy_sale(role_object,msg_data)
    local sale_index = msg_data.sale_index
    local gold_count = msg_data.gold_count
    local market_ruler = role_object:get_market_ruler()
    local result = market_ruler:buy_sale(sale_index,gold_count)
    return {result = result}
end

function MarketDispatcher.dispatcher_employ_businessman(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local businessman_index = msg_data.businessman_index
    local cash_count = msg_data.cash_count
    local market_ruler = role_object:get_market_ruler()
    local result = market_ruler:employ_businessman(timestamp,businessman_index,cash_count)
    return {result = result}
end

function MarketDispatcher.dispatcher_search_commodity(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local sale_index = msg_data.sale_index
    local market_ruler = role_object:get_market_ruler()
    local result = market_ruler:search_commodity(timestamp,sale_index)
    local commodity_objects = market_ruler:get_commodity_objects()
    return {result = result,commodity_objects = commodity_objects}
end

function MarketDispatcher.dispatcher_buy_commodity(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local commodity_index = msg_data.commodity_index
    local sale_index = msg_data.sale_index
    local item_count = msg_data.item_count
    local sale_price = msg_data.sale_price
    local market_ruler = role_object:get_market_ruler()
    local result = market_ruler:buy_commodity(timestamp,commodity_index,sale_index,item_count,sale_price)
    return {result = result}
end

return MarketDispatcher