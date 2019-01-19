local class = require "class"

local PlantEntry = class()

function PlantEntry:ctor(plant_config)  
    self.__plant_index = plant_config.product_index
    self.__plant_gold = plant_config.product_gold
    self.__plant_exp = plant_config.product_exp
    self.__finish_time = plant_config.finish_time
    self.__unlock_level = plant_config.unlock_level
end

function PlantEntry:get_plant_index()
    return self.__plant_index
end

function PlantEntry:get_consume_money()
    return self.__plant_gold
end

function PlantEntry:get_finish_time()
    return self.__finish_time
end

function PlantEntry:get_unlock_level()
    return self.__unlock_level
end

function PlantEntry:get_plant_exp()
    return self.__plant_exp
end

function PlantEntry:get_product_item()
    return self.__plant_index
end

return PlantEntry