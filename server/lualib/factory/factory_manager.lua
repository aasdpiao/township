local class = require "class"

local ProductEntry = require "factory.product_entry"
local datacenter = require "skynet.datacenter"
local print_r = require "print_r"
local syslog = require "syslog"

local FactoryManager = class()

function FactoryManager:ctor()
    self.__product_entrys = {}
end

function FactoryManager:init()
    self.load_product_config(self)
end

function FactoryManager:load_product_config()
    local product_config = datacenter.get("product_config")
    for k,v in pairs(product_config) do
        local product_index = v.product_index
        local product_entry = ProductEntry.new(v)
        self.__product_entrys[product_index] = product_entry
    end
end

function FactoryManager:get_product_entry(product_index)
    return self.__product_entrys[product_index]
end

return FactoryManager