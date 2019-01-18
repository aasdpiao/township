local ExpandEntry = class()

function ExpandEntry:ctor(unlock_index,unlock_cash)
    self.__unlock_index = unlock_index
    self.__unlock_cash = unlock_cash
end

function ExpandEntry:get_unlock_index()
    return self.__unlock_index
end

function ExpandEntry:get_unlock_cash()
    return self.__unlock_cash
end

return ExpandEntry