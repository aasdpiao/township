local BusinessmanEntry = class()

function BusinessmanEntry:ctor(businessman_index,employ_time,employ_cash,rest_time)
    self.__businessman_index = businessman_index
    self.__employ_time = employ_time
    self.__employ_cash = employ_cash
    self.__rest_time = rest_time
end

function BusinessmanEntry:get_businessman_index()
    return self.__businessman_index
end

function BusinessmanEntry:get_employ_time()
    return self.__employ_time
end

function BusinessmanEntry:get_employ_cash()
    return self.__employ_cash
end

function BusinessmanEntry:get_rest_time()
    return self.__rest_time
end

return BusinessmanEntry