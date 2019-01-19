local class = require "class"

local FactoryManager = require "factory.factory_manager"
local FactoryObject = require "factory.factory_object"
local FactoryDispatcher = require "factory.factory_dispatcher"
local packer = require "db.packer"
local syslog = require "syslog"

local FactoryRuler = class()

function FactoryRuler:ctor(role_object)
    self.__role_object = role_object
    self.__factory_objects = {}
end

function FactoryRuler:init()
    self.__factory_manager = FactoryManager.new()
    self.__factory_manager:init()

    self.__factory_dispatcher = FactoryDispatcher.new(self.__role_object)
    self.__factory_dispatcher:init()
end

function FactoryRuler:get_product_entry(product_index)
    return self.__factory_manager:get_product_entry(product_index)
end

function FactoryRuler:get_factory_entry(factory_index)
    return self.__role_object:get_grid_ruler():get_build_entry(factory_index)
end

function FactoryRuler:load_factory_data(factory_data)
    if not factory_data then return end
    local code = packer.decode(factory_data)
    local factory_objects = code.factory_objects
    if not factory_objects then return end
    for k,v in pairs(factory_objects) do
        local build_id = v.build_id
        local factory_object = self.get_factory_object(self,build_id)
        factory_object:load_factory_object(v)
    end
end

function FactoryRuler:dump_factory_data()
    local factory_data = {}
    factory_data.factory_objects = {}
    for k,v in pairs(self.__factory_objects) do
        table.insert(factory_data.factory_objects,v:dump_factory_object())
    end
    return factory_data
end

function FactoryRuler:serialize_factory_data()
    local factory_data = self.dump_factory_data(self)
    return packer.encode(factory_data)
end

function FactoryRuler:add_factory_object(build_id,factory_index)
    local factory_entry = self:get_factory_entry(factory_index)
    local factory_object = FactoryObject.new(self.__role_object,build_id,factory_entry)
    self.__factory_objects[build_id] = factory_object
end

function FactoryRuler:get_factory_object(build_id)
    return self.__factory_objects[build_id]
end

function FactoryRuler:debug_info()
    local factory_info = ""
    for build_id,factory_object in pairs(self.__factory_objects) do
        factory_info = factory_info..factory_object:debug_info().."\n"
    end
    return factory_info
end

return FactoryRuler