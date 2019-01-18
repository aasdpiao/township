local class = require "class"

local BuildRequire = class()

function BuildRequire:ctor(require_config)
    self.__build_index = require_config.product_index
    self.__product_gold = require_config.product_gold
    self.__product_exp = require_config.product_exp
    self.__unlock_level = require_config.unlock_level
    local formula = require_config.formula
    local formula_count = require_config.formula_count
    self.__formula = {}
    for i,v in ipairs(formula) do
        self.__formula[v] = formula_count[i]
    end
end

function BuildRequire:get_build_index()
    return self.__build_index
end

function BuildRequire:get_product_gold()
    return self.__product_gold
end

function BuildRequire:get_product_exp()
    return self.__product_exp
end

function BuildRequire:get_unlock_level()
    return self.__unlock_level
end

function BuildRequire:get_require_formula()
    return self.__formula
end

return BuildRequire
