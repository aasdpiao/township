local calss = require "class"

local UndevelopEntry = calss()

function UndevelopEntry:ctor(undevelop_config)
    self.__undevelop_index = undevelop_config.build_index
    self.__exp = undevelop_config.xp
    self.__gold = undevelop_config.gold
    self.__people = undevelop_config.property
    self.__finish_time = undevelop_config.btime
    local formula = undevelop_config.formula
    local formula_count = undevelop_config.formula_count
    self.__formula = {}
    for i,v in ipairs(formula) do
        self.__formula[v] = formula_count[k]
    end
end

function UndevelopEntry:get_undevelop_index()
    return self.__undevelop_index
end

function UndevelopEntry:get_exp()
    return self.__exp
end

function UndevelopEntry:get_gold()
    return self.__gold
end

function UndevelopEntry:get_people()
    return self.__people
end

function UndevelopEntry:get_finish_time()
    return self.__finish_time
end

function UndevelopEntry:get_formula()
    return self.__formula
end

return UndevelopEntry