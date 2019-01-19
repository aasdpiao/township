local class = require "class"

local datacenter = require "skynet.datacenter"
local PlantEntry = require "plant.plant_entry"

local PlantManager = class()

function PlantManager:ctor()
    self.__plant_entrys = {}
    local plant_config = datacenter.get("product_plant")
    for k,v in pairs(plant_config) do
        local plant_index = v.product_index
        local plant_entry = PlantEntry.new(v)
        self.__plant_entrys[plant_index] = plant_entry
    end
end

function PlantManager:init()

end

function PlantManager:get_plant_entry(plant_index)
    return self.__plant_entrys[plant_index]
end

return PlantManager