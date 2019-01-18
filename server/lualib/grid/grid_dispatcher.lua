local class = require "class"

local GridDispatcher = class()

function GridDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function GridDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function GridDispatcher:init()
    self:register_c2s_callback("create_build",self.dispatcher_create_build)
    self:register_c2s_callback("move_build",self.dispatcher_move_build)
    self:register_c2s_callback("promote_build",self.dispatcher_promote_build)
    self:register_c2s_callback("finish_build",self.dispatcher_finish_build)
    self:register_c2s_callback("remove_road",self.dispatcher_remove_road)
    self:register_c2s_callback("create_road",self.dispatcher_create_road)
    self:register_c2s_callback("remove_green",self.dispatcher_remove_green)
    self:register_c2s_callback("create_green",self.dispatcher_create_green)
    self:register_c2s_callback("create_floor",self.dispatcher_create_floor)
    self:register_c2s_callback("remove_floor",self.dispatcher_remove_floor)
    self:register_c2s_callback("open_undevelop",self.dispatcher_open_undevelop)
    self:register_c2s_callback("finish_undevelop",self.dispatcher_finish_undevelop)
    self:register_c2s_callback("promote_undevelop",self.dispatcher_promote_undevelop)
    self:register_c2s_callback("add_worker",self.dispatcher_add_worker)
    self:register_c2s_callback("get_off_work",self.dispatcher_get_off_work)
    self:register_c2s_callback("sell_build",self.dispatcher_sell_build)
    self:register_c2s_callback("storage_build",self.dispatcher_storage_build)
end

function GridDispatcher.dispatcher_sell_build(role_object,msg_data)
    local gold_count = msg_data.gold_count
    local grid_id = msg_data.grid_id
    local result = role_object:get_grid_ruler():sell_build_object(grid_id)
    return {result = result}
end

function GridDispatcher.dispatcher_storage_build(role_object,msg_data)
    local grid_id = msg_data.grid_id
    local result = role_object:get_grid_ruler():storage_build(grid_id)
    return {result = result}
end

--创建建筑
function GridDispatcher.dispatcher_create_build(role_object,msg_data)
    local build_objects = msg_data.build_objects
    for i,build_object in ipairs(build_objects) do
        local result = role_object:get_grid_ruler():creat_grid_object(build_object)
        if result > 0 then return {result = result} end
    end
    return {result = 0}
end

--移动建筑
function GridDispatcher.dispatcher_move_build(role_object,msg_data)
    local source_grid_id = msg_data.source_grid_id
    local build_object = msg_data.build_object
    local result = role_object:get_grid_ruler():move_build(source_grid_id,build_object)
    return {result = result}
end

--加速建造
function GridDispatcher.dispatcher_promote_build(role_object,msg_data)
    local cash_count = msg_data.cash_count
    local build_object = msg_data.build_object
    local build_id = build_object.build_id
    local timestamp = build_object.timestamp
    local result = role_object:get_grid_ruler():promote_build(build_id,timestamp,cash_count)
    return {result = result}
end

--完成建筑
function GridDispatcher.dispatcher_finish_build(role_object,msg_data)
    local build_object = msg_data.build_object
    local build_id = build_object.build_id
    local item_objects = msg_data.item_objects
    local timestamp = build_object.timestamp
    local result = role_object:get_grid_ruler():finish_build(build_id,timestamp,item_objects)
    return {result = result}
end

function GridDispatcher.dispatcher_remove_road(role_object,msg_data)
    local road_objects = msg_data.road_objects
    for i,v in ipairs(road_objects) do
        local grid_id = v.grid_id
        role_object:get_grid_ruler():remove_road_object(grid_id)
    end
    return {result = 0}
end

function GridDispatcher.dispatcher_create_road(role_object,msg_data)
    local road_objects = msg_data.road_objects
    for i,v in ipairs(road_objects) do
        local element_index = v.element_index
        local grid_id = v.grid_id
        role_object:get_grid_ruler():create_road_object(element_index,grid_id)
    end
    return {result = 0}
end

function GridDispatcher.dispatcher_remove_green(role_object,msg_data)
    local green_objects = msg_data.green_objects
    for i,v in ipairs(green_objects) do
        local grid_id = v.grid_id
        role_object:get_grid_ruler():remove_green_object(grid_id)
    end
    return {result = 0}
end

function GridDispatcher.dispatcher_create_green(role_object,msg_data)
    local green_objects = msg_data.green_objects
    for i,v in ipairs(green_objects) do
        local element_index = v.element_index
        local grid_id = v.grid_id
        role_object:get_grid_ruler():create_green_object(element_index,grid_id)
    end
    return {result = 0}
end

function GridDispatcher.dispatcher_create_floor(role_object,msg_data)
    local floor_objects = msg_data.floor_objects
    for i,v in ipairs(floor_objects) do
        local element_index = v.element_index
        local grid_id = v.grid_id
        role_object:get_grid_ruler():create_floor_object(element_index,grid_id)
    end
    return {result = 0}
end

function GridDispatcher.dispatcher_remove_floor(role_object,msg_data)
    local floor_objects = msg_data.floor_objects
    for i,v in ipairs(floor_objects) do
        local grid_id = v.grid_id
        role_object:get_grid_ruler():remove_floor_object(grid_id)
    end
    return {result = 0}
end

function GridDispatcher.dispatcher_open_undevelop(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local grid_id = msg_data.grid_id
    local result = role_object:get_grid_ruler():open_undevelop_object(timestamp,grid_id)
    return {result = result}
end

function GridDispatcher.dispatcher_finish_undevelop(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local grid_id = msg_data.grid_id
    local result = role_object:get_grid_ruler():finish_undevelop_object(timestamp,grid_id)
    return {result = result}
end

function GridDispatcher.dispatcher_promote_undevelop(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local grid_id = msg_data.grid_id
    local cash_count = msg_data.cash_count
    local result = role_object:get_grid_ruler():promote_undevelop_object(timestamp,grid_id,cash_count)
    return {result = result}
end

function GridDispatcher.dispatcher_add_worker(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local build_id = msg_data.build_id
    local worker_id = msg_data.worker_id

    local build_object = role_object:get_grid_ruler():get_build_object(build_id)
    local build_type = 5
    if build_object then
        build_type = build_object:get_build_entry():get_build_type()
    end

    local result  = 0

    if build_type == 1 then                 --农场
        local plant_ruler = role_object:get_plant_ruler()
        result = plant_ruler:employment_worker_object(worker_id,timestamp)
    elseif build_type == 2 then             --工厂
        local factory_object = role_object:get_factory_ruler():get_factory_object(build_id)
        result = factory_object:employment_worker_object(worker_id,timestamp)
    elseif build_type == 5 then
        if build_id == 5001001 then         --火车站
            local trains_ruler = role_object:get_trains_ruler()
            result = trains_ruler:employment_worker_object(worker_id,timestamp)
        elseif build_id == 5002001 then     --飞机场
            local flight_ruler = role_object:get_flight_ruler()
            result = flight_ruler:employment_worker_object(worker_id,timestamp)
        elseif build_id == 5003001 then     --直升飞机场 
            local helicopter_ruler = role_object:get_helicopter_ruler()
            result = helicopter_ruler:employment_worker_object(worker_id,timestamp)
        elseif build_id == 5004001 then     --仓库
            local item_ruler = role_object:get_item_ruler()
            result = item_ruler:employment_worker_object(worker_id,timestamp)
        elseif build_id == 5005001 then     --市场
            local market_ruler = role_object:get_market_ruler()
            result = market_ruler:employment_worker_object(worker_id,timestamp)
        elseif build_id == 5006001 then     --市政府
            local achievement_ruler = role_object:get_achievement_ruler()
            result = achievement_ruler:employment_worker_object(worker_id,timestamp)
        elseif build_id == 5007001 then     --港口
            local seaport_ruler = role_object:get_seaport_ruler()
            result = seaport_ruler:employment_worker_object(worker_id,timestamp)
        end
    elseif build_type == 6 then             --饲养场
        local feed_ruler = role_object:get_feed_ruler()
        local feed_object = feed_ruler:get_feed_object(build_id)
        result = feed_object:employment_worker_object(worker_id,timestamp)
    end
    return {result = result}
end

function GridDispatcher.dispatcher_get_off_work(role_object,msg_data)
    local timestamp = msg_data.timestamp
    local build_id = msg_data.build_id

    local build_object = role_object:get_grid_ruler():get_build_object(build_id)
    local build_type = 5
    if build_object then
        build_type = build_object:get_build_entry():get_build_type()
    end
    local result  = 0

    if build_type == 1 then
        local plant_ruler = role_object:get_plant_ruler()
        result = plant_ruler:get_off_work(timestamp)
    elseif build_type == 2 then
        local factory_object = role_object:get_factory_ruler():get_factory_object(build_id)
        result = factory_object:get_off_work(timestamp)
    elseif build_type == 5 then
        if build_id == 5001001 then         --火车站
            local trains_ruler = role_object:get_trains_ruler()
            result = trains_ruler:get_off_work(timestamp)
        elseif build_id == 5002001 then     --飞机场
            local flight_ruler = role_object:get_flight_ruler()
            result = flight_ruler:get_off_work(timestamp)
        elseif build_id == 5003001 then     --直升飞机场 
            local helicopter_ruler = role_object:get_helicopter_ruler()
            result = helicopter_ruler:get_off_work(timestamp)
        elseif build_id == 5004001 then     --仓库
            local item_ruler = role_object:get_item_ruler()
            result = item_ruler:get_off_work(timestamp)
        elseif build_id == 5005001 then     --市场
            local market_ruler = role_object:get_market_ruler()
            result = market_ruler:get_off_work(timestamp)
        elseif build_id == 5006001 then     --市政府
            local achievement_ruler = role_object:get_achievement_ruler()
            result = achievement_ruler:get_off_work(timestamp)
        elseif build_id == 5007001 then     --港口
            local seaport_ruler = role_object:get_seaport_ruler()
            result = seaport_ruler:get_off_work(timestamp)
        end
    elseif build_type == 6 then
        local feed_ruler = role_object:get_feed_ruler()
        local feed_object = feed_ruler:get_feed_object(build_id)
        result = feed_object:get_off_work(timestamp)
    end
    return {result = result}
end

return GridDispatcher