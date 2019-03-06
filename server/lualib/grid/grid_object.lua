local class = require "class"
local grid_const = require "grid.grid_const"
local cjson = require "cjson"
local GridObject = class()

function GridObject:ctor(role_object,build_id,build_entry,grid_id,flip,timestamp)
    self.__role_object = role_object
    self.__build_id = build_id
    self.__grid_id = grid_id
    self.__flip = flip
    self.__build_entry = build_entry
    self.__timestamp = timestamp
    self.__status = grid_const.default
end

function GridObject:get_build_id()
    return self.__build_id
end

function GridObject:get_grid_id()
    return self.__grid_id
end

function GridObject:set_grid_id(grid_id)
    self.__grid_id = grid_id
end

function GridObject:set_flip(flip)
    self.__flip = flip
end

function GridObject:get_build_entry()
    return self.__build_entry
end

function GridObject:get_build_index()
    return self.__build_entry:get_build_index()
end

function GridObject:dump_grid_object()
    local grid_data = {}
    grid_data.grid_id = self.__grid_id
    grid_data.build_id = self.__build_id
    grid_data.build_index = self.__build_entry:get_build_index()
    grid_data.flip = self.__flip
    grid_data.timestamp = self.__timestamp
    grid_data.status = self.__status
    return grid_data
end

function GridObject:get_create_time()
    return self.__timestamp
end

function GridObject:get_finish_time()
    local unlock_entry = self.__role_object:get_grid_ruler():get_unlock_entry(self.__build_id)
    if not unlock_entry then return 0 end
    return unlock_entry:get_finish_time()
end

function GridObject:check_can_finish(timestamp)
    if self.__status == grid_const.promote then return true end
    local finish_time = self:get_finish_time()
    local create_time = self.get_create_time(self)
    if create_time <= 0 then return false end
    return create_time + finish_time <= timestamp
end

function GridObject:check_can_promote(timestamp)
    return self.__status == grid_const.building
end

function GridObject:set_grid_promote()
    self.set_status(self,grid_const.promote)
end

function GridObject:finish_build()
    self.set_status(self,grid_const.finish)
end

function GridObject:set_init_build()
    self.set_status(self,grid_const.init)
end

function GridObject:set_status(status)
    self.__status = status
end

function GridObject:building_grid()
    local finish_time = self:get_finish_time()
    if finish_time > 0 then
        self.__status = grid_const.building
    else
        self.__status = grid_const.finish
        self.__role_object:get_event_ruler():main_task_build(self:get_build_index())
    end
end

function GridObject:check_avalible()
    return self.__status == grid_const.init or self.__status == grid_const.finish
end

return GridObject