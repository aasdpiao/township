local class = require "class"

local CacheObject = class()

function CacheObject:ctor(account_id)
    self.__account_id = account_id
end

return CacheObject