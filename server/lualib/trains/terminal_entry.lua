local class = require "class"
local TerminialEntry = class()

function TerminialEntry:ctor(terminal_config)
    self.__terminal_index = terminal_config.index
    self.__unlock_level = terminal_config.unlock_level
    self.__travel_time = terminal_config.travel_time
    self.__terminal_weight = terminal_config.terminal_weight
end

function TerminialEntry:get_terminal_index()
    return self.__terminal_index
end

function TerminialEntry:get_unlock_level()
    return self.__unlock_level
end

function TerminialEntry:get_travel_time()
    return self.__travel_time
end

function TerminialEntry:get_terminal_weight()
    return self.__terminal_weight
end

function TerminialEntry:check_terminal_available(role_object)
    return role_object:check_level(self.__unlock_level)
end

return TerminialEntry