local ExpandEntry = class()

function ExpandEntry:ctor(barn_level,barn_config)
    self.__barn_level = barn_config.barn_level
    self.__barn_size = barn_config.barn_size
    local need_item = barn_config.need_item
    local need_count = barn_config.need_count
    self.__item_objects = {}
    for i,v in ipairs(need_item) do
        local count = need_count[i]
        self.__item_objects[v] = count
    end
end

function ExpandEntry:get_item_capacity()
    return self.__barn_size
end

function ExpandEntry:get_item_objects()
    return self.__item_objects
end

return ExpandEntry