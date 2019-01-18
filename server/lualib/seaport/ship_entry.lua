local class = require "class"

local ShipEntry = class()

function ShipEntry:ctor(unlock_entry)
    self.__ship_index = unlock_entry:get_build_id()
    self.__unlock_entry = unlock_entry
end

function ShipEntry:get_ship_index()
    return self.__ship_index
end

function ShipEntry:get_unlock_gold()
    return self.__unlock_entry:get_gold()
end

function ShipEntry:get_unlock_level()
    return self.__unlock_entry:get_level()
end

function ShipEntry:get_unlock_people()
    return self.__unlock_entry:get_people()
end

return ShipEntry