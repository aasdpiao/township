local class = require "class"

local WorkerState = class()
-- data[1] = { 
--     index_id = 1,  
--     worker_type = 1,  
--     star_id = 1,  
--     starup_require = {1001,1002,1003,1004},  
--     starup_count = {1,2,3,4}}

function WorkerState:ctor(star_config)
    self.__state = star_config.star_id

    local topaz = star_config.starup_count[1]
    local emerald = star_config.starup_count[2]
    local ruby = star_config.starup_count[3]
    local amethyst = star_config.starup_count[4]

    self.__topaz = topaz
    self.__emerald = emerald
    self.__ruby = ruby
    self.__amethyst = amethyst
end

function WorkerState:get_topaz()
    return self.__topaz
end

function WorkerState:get_emerald()
    return self.__emerald
end

function WorkerState:get_ruby()
    return self.__ruby
end

function WorkerState:get_amethyst()
    return self.__amethyst
end

return WorkerState