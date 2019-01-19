local class = require "class"

local PersonEntry = class()

function PersonEntry:ctor(person_config)
    self.__person_index = person_config.index
end

function PersonEntry:get_person_index()
    return self.__person_index
end

return PersonEntry