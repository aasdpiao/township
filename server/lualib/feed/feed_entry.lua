local class = require "class"

local FeedEntry = class()

function FeedEntry:ctor(feed_config)
    self.__product_index = feed_config.product_index
    self.__product_exp = feed_config.product_exp
    self.__formula = {}
    local formula = feed_config.formula
    local formula_count = feed_config.formula_count
    for i,v in ipairs(formula) do
        self.__formula[v] = formula_count[i]
    end
    self.__finish_time = feed_config.finish_time
end

function FeedEntry:get_formula()
    return self.__formula
end

function FeedEntry:get_product_index()
    return self.__product_index
end

function FeedEntry:get_product_exp()
    return self.__product_exp
end

function FeedEntry:get_product_item()
    return self.__product_index
end

function FeedEntry:get_finish_time()
    return self.__finish_time
end

return FeedEntry