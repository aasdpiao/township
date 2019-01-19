local class = require "class"
local BuildEntry = require "grid.build_entry"
local UnlockEntry = require "grid.unlock_entry"
local BuildRequire = require "grid.build_require"
local UndevelopEntry = require "grid.undevelop_entry"
local datacenter = require "skynet.datacenter"
local syslog = require "syslog"

local BuildManager = class()

function BuildManager:ctor()
    self.__build_entrys = {}
    self.__unlock_entrys = {}
    self.__build_requires = {}
    self.__undevelop_entrys = {}
end

function BuildManager:init()
    self.load_build_config(self)
    self.load_unlock_config(self)
    self.load_build_require(self)
    self.load_undevelop_config(self)
end

function BuildManager:load_build_config()
    local build_config = datacenter.get("build_config")
    for k,v in pairs(build_config) do
        local build_index = v.build_index
        local build_entry = BuildEntry.new(v)
        self.__build_entrys[build_index] = build_entry
    end
end

function BuildManager:load_unlock_config()
    local unlock_config = datacenter.get("build_unlock_config")
    for k,v in pairs(unlock_config) do
        local build_id = v.build_id
        local build_index = v.build_index
        local build_entry = self.get_build_entry(self,build_index)
        assert(build_entry,"build_index:"..build_index)
        local unlock_entry = UnlockEntry.new(v,build_entry)
        self.__unlock_entrys[build_id] = unlock_entry
        build_entry:add_unlock_entry(unlock_entry)
    end
end

function BuildManager:load_build_require()
    local build_require = datacenter.get("product_build")
    for k,v in pairs(build_require) do
        local product_index = v.product_index
        local build_require = BuildRequire.new(v)
        self.__build_requires[product_index] = build_require
    end
end

function BuildManager:load_undevelop_config()
    local undeveloped_config = datacenter.get("undeveloped_config")
    for k,v in pairs(undeveloped_config) do
        local undevelop_index = v.build_index
        local undevelop_entry = UndevelopEntry.new(v)
        self.__undevelop_entrys[undevelop_index] = undevelop_entry
    end
end

function BuildManager:get_build_require(build_index)
    return self.__build_requires[build_index]
end

function BuildManager:get_build_entry(build_index)
    return self.__build_entrys[build_index]
end

function BuildManager:get_unlock_entry(build_id)
    return self.__unlock_entrys[build_id]
end

function BuildManager:get_undevelop_entry(undevelop_index)
    return self.__undevelop_entrys[undevelop_index]
end

return BuildManager