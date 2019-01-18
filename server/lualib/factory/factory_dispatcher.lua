local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local FactoryDispatcher = class()

function FactoryDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function FactoryDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function FactoryDispatcher:init()
    self:register_c2s_callback("start_product",self.dispatcher_start_product)
    self:register_c2s_callback("harvest_product",self.dispatcher_harvest_product)
    self:register_c2s_callback("promote_product",self.dispatcher_promote_product)
    self:register_c2s_callback("add_product_slot",self.dispatcher_add_product_slot)
end 

function FactoryDispatcher.dispatcher_start_product(role_object,msg_data)
    local build_id = msg_data.build_id
    local product_objects = msg_data.product_objects
    local factory_object = role_object:get_factory_ruler():get_factory_object(build_id)
    assert(factory_object)
    local result = factory_object:start_product(product_objects)
    return { result = result}
end

function FactoryDispatcher.dispatcher_harvest_product(role_object,msg_data)
    local build_id = msg_data.build_id
    local storage_objects = msg_data.storage_objects
    local factory_object = role_object:get_factory_ruler():get_factory_object(build_id)
    assert(factory_object)
    local result = factory_object:harvest_product(storage_objects)
    return { result = result}
end

function FactoryDispatcher.dispatcher_promote_product(role_object,msg_data)
    local build_id = msg_data.build_id
    local product_object = msg_data.product_object
    local factory_object = role_object:get_factory_ruler():get_factory_object(build_id)
    assert(factory_object)
    local result = factory_object:promote_product(product_object)
    return { result = result}
end

function FactoryDispatcher.dispatcher_add_product_slot(role_object,msg_data)
    local build_id = msg_data.build_id
    local cash_count = msg_data.cash_count
    local slot_index = msg_data.slot_index
    local factory_object = role_object:get_factory_ruler():get_factory_object(build_id)
    assert(factory_object,"factory_object is nil")
    local result = factory_object:add_product_slot(slot_index,cash_count)
    return { result = result}
end

return FactoryDispatcher

