local class = require "class"
local utils = require "utils"

local EmployEntry = class()

function EmployEntry:ctor(employ_config)
    self.__employ_index = employ_config.employ_index
    self.__employ_type = employ_config.employ_type
    local states = employ_config.states
    local states_weight = employ_config.states_weight
    self.__free_interval = employ_config.free_interval
    self.__free_times = employ_config.free_times
    self.__states = {}
    self.__states_weight = 0
    for i,v in ipairs(states) do
        local state_weight = states_weight[i]
        local state_element = {v,state_weight}
        table.insert( self.__states, state_element)
        self.__states_weight = self.__states_weight + state_weight
    end
    local professions = employ_config.profession
    local professions_weight = employ_config.profession_weight
    self.__professions = {}
    self.__professions_weight = 0
    for i,v in ipairs(professions) do
        local profession_weight = professions_weight[i]
        local profession_element = {v,profession_weight}
        table.insert(self.__professions, profession_element)
        self.__professions_weight = self.__professions_weight + profession_weight
    end
end

function EmployEntry:get_worker_object()
    local state = utils.get_random_value_in_weight(self.__states_weight,self.__states)
    local profession = utils.get_random_value_in_weight(self.__professions_weight,self.__professions)
    local worker_object = {}
    worker_object.state = state
    worker_object.profession = profession
    return worker_object
end

function EmployEntry:get_free_times()
    return self.__free_times
end

function EmployEntry:get_free_interval()
    return self.__free_interval
end

return EmployEntry