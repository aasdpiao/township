local class = require "class"
local syslog = require "syslog"

local PeopleRuler = class()

function PeopleRuler:ctor(role_object)
    self.__role_object = role_object
    self.__default_people = 75    
    self.__max_people_builds = {}
    self.__people_builds = {}
end

function PeopleRuler:init()
end

function PeopleRuler:add_max_people(build_id)
    local build_object = self.__role_object:get_grid_ruler():get_build_object(build_id)
    self.__max_people_builds[build_id] = build_object
end

function PeopleRuler:add_current_people(build_id)
    local build_object = self.__role_object:get_grid_ruler():get_build_object(build_id)
    self.__people_builds[build_id] = build_object
end

function PeopleRuler:get_max_people()
    local max_people = self.__default_people
    for k,v in pairs(self.__max_people_builds) do
        if v:check_avalible() then
            max_people = max_people + v:get_build_entry():get_max_people()
        end
    end
    return max_people
end

function PeopleRuler:get_people()
    local people = 0
    for k,v in pairs(self.__people_builds) do
        if v:check_avalible() then
            people = people + v:get_build_entry():get_people()
        end
    end
    return people
end

return PeopleRuler