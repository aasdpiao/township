local class = require "class"

local ProductEntry = class()

function ProductEntry:ctor(product_config)
    self.__product_index = product_config.product_index
    self.__product_gold = product_config.product_gold
    self.__product_exp = product_config.product_exp
    self.__unlock_level = product_config.unlock_level
    self.__finish_time = product_config.finish_time
    self.__product_count = product_config.product_count
    self.__formula = {}
    local formula = product_config.formula
    local formula_count = product_config.formula_count
    for i,v in ipairs(formula) do
        self.__formula[v] = formula_count[i]
    end
end

function ProductEntry:get_unlock_level()
    return self.__unlock_level
end

function ProductEntry:get_formula()
    return self.__formula
end

function ProductEntry:get_product_exp()
    return self.__product_exp
end

function ProductEntry:get_finish_time()
    return self.__finish_time
end

function ProductEntry:get_product_count()
    return self.__product_count
end

return ProductEntry