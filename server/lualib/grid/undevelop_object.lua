local class = require "class"
local grid_const = require "grid.grid_const"

local UndevelopObject = class()

function UndevelopObject:ctor(role_object,undevelop_index,timestamp,grid_id,status)
    self.__role_object = role_object
    self.__undevelop_index = undevelop_index
    self.__timestamp = timestamp
    self.__grid_id = grid_id
    self.__status = status or grid_const.default
end

function UndevelopObject:dump_undevelop_object()
    local undevelop_object = {}
    undevelop_object.timestamp = self.__timestamp
    undevelop_object.grid_id = self.__grid_id
    undevelop_object.status = self.__status
    undevelop_object.undevelop_index =  self.__undevelop_index
    return undevelop_object
end

function UndevelopObject:check_can_finish(timestamp)
    if self.__status == grid_const.promote then return true end
    local undevelop_entry = self.__role_object:get_grid_ruler():get_undevelop_entry(self.__undevelop_index)
    assert(undevelop_entry,"undevelop_index:"..self.__undevelop_index)
    local finish_time = undevelop_entry:get_finish_time()
    if timestamp < finish_time + self.__timestamp then return false end
    return true
end

function UndevelopObject:check_can_promote(timestamp)
    if self.__status == grid_const.promote then return false end
    local undevelop_entry = self.__role_object:get_grid_ruler():get_undevelop_entry(self.__undevelop_index)
    assert(undevelop_entry,"undevelop_index:"..self.__undevelop_index)
    local finish_time = undevelop_entry:get_finish_time()
    if timestamp < finish_time + self.__timestamp then return true end
    return false
end

function UndevelopObject:get_finish_exp()
    local undevelop_entry = self.__role_object:get_grid_ruler():get_undevelop_entry(self.__undevelop_index)
    assert(undevelop_entry,"undevelop_index:"..self.__undevelop_index)
    return undevelop_entry:get_exp()
end

function UndevelopObject:promote_undevelop_object()
    self.__status = grid_const.promote
end

function UndevelopObject:get_remain_time(timestamp)
    local undevelop_entry = self.__role_object:get_grid_ruler():get_undevelop_entry(self.__undevelop_index)
    assert(undevelop_entry,"undevelop_index:"..self.__undevelop_index)
    local finish_time = undevelop_entry:get_finish_time()
    return finish_time + self.__timestamp - timestamp
end

return UndevelopObject