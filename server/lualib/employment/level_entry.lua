local class = require "class"

local LevelupEntry = class()

function LevelupEntry:ctor(levelup_config)
    self.__level = levelup_config.level
end

return LevelupEntry