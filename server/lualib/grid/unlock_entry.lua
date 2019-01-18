local class = require "class"

local UnlockEntry = class()

function UnlockEntry:ctor(unlock_config,build_entry)
    self.__build_id = unlock_config.build_id
    self.__build_entry = build_entry
    self.__build_index = unlock_config.build_index
    self.__finish_time = unlock_config.finish_time
    self.__product_exp = unlock_config.product_exp
    self.__unlock_attr = {}

    local unlock_condition = unlock_config.unlock
    local condition_values = unlock_config.unlock_count

    for k,v in pairs(unlock_config) do
        if k ~= "unlock" and k ~= "unlock_count" then
            self.__unlock_attr[k] = v
        end
    end

    for k,v in pairs(unlock_condition) do
        self.__unlock_attr[v] = condition_values[k]
    end
end

function UnlockEntry:get_unlock_attr(key,default)
    return self.__unlock_attr[key] or default
end

function UnlockEntry:get_build_id()
    return self.__build_id
end

function UnlockEntry:get_people()
    return self.get_unlock_attr(self,"people",0)
end

function UnlockEntry:get_gold()
    return self.get_unlock_attr(self,"gold",0)
end

function UnlockEntry:get_level()
    return self.get_unlock_attr(self,"level",0)
end

function UnlockEntry:get_friendly()
    return self.get_unlock_attr(self,"friendly",0)
end

function UnlockEntry:get_finish_time()
    return self.__finish_time
end

function UnlockEntry:get_product_exp()
    return self.__product_exp
end

return UnlockEntry