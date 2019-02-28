local class = require "class"
local BuildManager = require "grid.build_manager"
local GridObject = require "grid.grid_object"
local GridDispatcher = require "grid.grid_dispatcher"
local UndevelopObject = require "grid.undevelop_object"
local datacenter = require "skynet.datacenter"
local packer = require "db.packer"
local syslog = require "syslog"
local grid_const = require "grid.grid_const"
local GridRuler = class()

function GridRuler:ctor(role_object)
    self.__role_object = role_object
    self.__undevelop_count = 0
    self.__grid_objects = {}
    self.__build_objects = {}
    self.__undevelop_objects = {}
    self.__road_objects = {}
    self.__floor_objects = {}
    self.__green_objects = {}
    self.__building_undevelops = {}
    self.__storage_builds = {}
end

function GridRuler:init()
    self.__build_manager = BuildManager.new()
    self.__build_manager:init()
    self.__grid_dispatcher = GridDispatcher.new(self.__role_object)
    self.__grid_dispatcher:init()
end

function GridRuler:get_build_entry(build_index)
    return self.__build_manager:get_build_entry(build_index)
end

function GridRuler:get_unlock_entry(build_id)
    return self.__build_manager:get_unlock_entry(build_id)
end

function GridRuler:get_build_require(build_index)
    return self.__build_manager:get_build_require(build_index)
end

function GridRuler:get_undevelop_entry(undevelop_index)
    return self.__build_manager:get_undevelop_entry(undevelop_index)
end

function GridRuler:load_grid_data(grid_data)
    if not grid_data then
        local build_data = datacenter.get("build_data")
        local floor_data = datacenter.get("floor_data")
        local green_data = datacenter.get("green_data")
        local road_data = datacenter.get("road_data")
        local ground_data = datacenter.get("ground_data")
        for k,v in pairs(build_data) do
            local build_index = v[1]
            local build_id = v[2]
            local grid_id = v[3]
            local flip = v[4]
            local timestamp = self.__role_object:get_time_ruler():get_current_time()
            local grid_object = self.new_grid_object(self,build_id,build_index,grid_id,flip,timestamp)
            grid_object:set_init_build()
            self.add_grid_object(self,grid_object)
        end
        for k,v in pairs(floor_data) do
            local element_index = v[1]
            local grid_id = v[2]
            self.__floor_objects[grid_id] = element_index
        end
        for k,v in pairs(green_data) do
            local element_index = v[1]
            local grid_id = v[2]
            self.__green_objects[grid_id] = element_index
        end
        for k,v in pairs(road_data) do
            local element_index = v[1]
            local grid_id = v[2]
            self.__road_objects[grid_id] = element_index
        end
        for k,v in pairs(ground_data) do
            local element_index = v[1]
            local grid_id = v[2]
            self.__undevelop_objects[grid_id] = element_index
        end
        return
    end
    local code = packer.decode(grid_data)
    self.__undevelop_count = code.undevelop_count
    local storage_builds = code.storage_builds
    for i,v in ipairs(storage_builds) do
        local build_index = v.build_index
        local build_count = v.build_count
        self.__storage_builds[build_index] = build_count
    end
    local undevelop_objects = code.undevelop_objects
    local road_objects = code.road_objects
    local floor_objects = code.floor_objects
    local green_objects = code.green_objects
    local build_objects = code.build_objects
    local building_undevelops = code.building_undevelops
    for k,v in ipairs(build_objects) do
        local build_index = v.build_index
        local build_id = v.build_id
        local grid_id = v.grid_id
        local flip = v.flip
        local timestamp = v.timestamp
        local status = v.status
        local grid_object = self.new_grid_object(self,build_id,build_index,grid_id,flip,timestamp)
        grid_object:set_status(status)
        self.add_grid_object(self,grid_object) 
    end
    for i,v in ipairs(building_undevelops) do
        local timestamp = v.timestamp
        local grid_id = v.grid_id
        local status = v.status
        local undevelop_index = v.undevelop_index
        local undevelop_object = UndevelopObject.new(self.__role_object,undevelop_index,timestamp,grid_id,status)
        self.__building_undevelops[grid_id] = undevelop_object
    end
    for i,v in ipairs(road_objects) do
        local element_index = v.element_index
        local grid_id = v.grid_id
        self.__road_objects[grid_id] = element_index
    end
    for i,v in ipairs(floor_objects) do
        local element_index = v.element_index
        local grid_id = v.grid_id
        self.__floor_objects[grid_id] = element_index
    end
    for i,v in ipairs(green_objects) do
        local element_index = v.element_index
        local grid_id = v.grid_id
        self.__green_objects[grid_id] = element_index
    end
    for i,v in ipairs(undevelop_objects) do
        local element_index = v.element_index
        local grid_id = v.grid_id
        self.__undevelop_objects[grid_id] = element_index
    end
end

function GridRuler:dump_grid_data()
    local grid_data = {}
    grid_data.undevelop_count = self.__undevelop_count
    grid_data.storage_builds = {}
    for k,v in pairs(self.__storage_builds) do
        table.insert(grid_data.storage_builds,{build_index = k,build_count = v})
    end
    grid_data.build_objects = {}
    for k,v in pairs(self.__grid_objects) do
        local grid_object = v:dump_grid_object()
        table.insert( grid_data.build_objects, grid_object)
    end
    grid_data.undevelop_objects = {}
    for k,v in pairs(self.__undevelop_objects) do
        local undevelop_object = {}
        undevelop_object.grid_id = k
        undevelop_object.element_index = v
        table.insert( grid_data.undevelop_objects, undevelop_object)
    end
    grid_data.building_undevelops = {}
    for k,v in pairs(self.__building_undevelops) do
        local building_undevelop = v:dump_undevelop_object()
        table.insert( grid_data.building_undevelops, building_undevelop)
    end
    grid_data.road_objects = {}
    for k,v in pairs(self.__road_objects) do
        local road_object = {}
        road_object.grid_id = k
        road_object.element_index = v
        table.insert( grid_data.road_objects, road_object)
    end
    grid_data.floor_objects = {}
    for k,v in pairs(self.__floor_objects) do
        local floor_object = {}
        floor_object.grid_id = k
        floor_object.element_index = v
        table.insert( grid_data.floor_objects, floor_object)
    end
    grid_data.green_objects = {}
    for k,v in pairs(self.__green_objects) do
        local green_object = {}
        green_object.grid_id = k
        green_object.element_index = v
        table.insert( grid_data.green_objects, green_object)
    end
    return grid_data
end

function GridRuler:serialize_grid_data()
    local grid_data = self.dump_grid_data(self)
    return packer.encode(grid_data)
end

function GridRuler:add_grid_object(grid_object)
    local grid_id = grid_object:get_grid_id()
    self.__grid_objects[grid_id] = grid_object
    local build_id = grid_object:get_build_id()
    if build_id > 0 then 
        self.__build_objects[build_id] = grid_object
    end
    local build_index = grid_object:get_build_entry():get_build_index()
    if build_index == 1001 then
        self.__role_object:get_plant_ruler():add_plant_object(build_id)
    elseif build_index > 2000 and build_index < 3000 then
        self.__role_object:get_factory_ruler():add_factory_object(build_id,build_index)
    elseif build_index > 3000 and build_index < 4000 then
        self.__role_object:get_people_ruler():add_max_people(build_id)
    elseif build_index > 4000 and build_index < 5000 then
        self.__role_object:get_people_ruler():add_current_people(build_id)
    elseif build_index > 6000 and build_index < 7000 then
        self.__role_object:get_feed_ruler():add_feed_object(build_id,build_index)
    end
end

function GridRuler:get_grid_object(grid_id)
    return self.__grid_objects[grid_id]
end

function GridRuler:get_build_object(build_id)
    return self.__build_objects[build_id]
end

function GridRuler:new_grid_object(build_id,build_index,grid_id,flip,timestamp)
    local build_entry = self.get_build_entry(self,build_index)
    assert(build_entry)
    local grid_object = GridObject.new(self.__role_object,build_id,build_entry,grid_id,flip,timestamp)
    return grid_object
end

function GridRuler:creat_grid_object(build_object)
    local build_id = build_object.build_id
    local build_index = build_object.build_index
    local grid_id = build_object.grid_id
    local flip = build_object.flip
    local timestamp = build_object.timestamp
    local grid_object = self.get_grid_object(self,grid_id)
    if grid_object then
        LOG_ERROR("grid_id:%d error:%s", grid_id, errmsg(GAME_ERROR.grid_id_exist))
        return GAME_ERROR.grid_id_exist 
    end
    local build_object = self.get_build_object(self,build_id)
    if build_object then
        LOG_ERROR("build_id:%d error:%s", build_id, errmsg(GAME_ERROR.build_id_exist))
        return GAME_ERROR.build_id_exist
    end
    if build_id == 0 then
        build_id = build_index * 1000 + 1
    end
    local unlock_entry = self.get_unlock_entry(self,build_id) 
    if unlock_entry then
        local people = unlock_entry:get_people()
        local gold = unlock_entry:get_gold()
        local level = unlock_entry:get_level()
        local friendly = unlock_entry:get_friendly()
        if people > 0 then
            local current_people = self.__role_object:get_people_ruler():get_people()
            if current_people < people then
                LOG_ERROR("people:%d current_people:%d error:%s", people, current_people, errmsg(GAME_ERROR.people_not_enough))
                return GAME_ERROR.people_not_enough 
            end
        end
        if gold > 0 then
            if not self.__role_object:check_enough_gold(gold) then
                LOG_ERROR("gold:%d error:%s", gold, errmsg(GAME_ERROR.gold_not_enough))
                return GAME_ERROR.gold_not_enough  
            end
        end
        if level > 0 then
            if not self.__role_object:check_level(level) then
                LOG_ERROR("level:%d error:%s", level, errmsg(GAME_ERROR.level_not_enough))
                return GAME_ERROR.level_not_enough
            end
        end
        if friendly > 0 then
            if not self.__role_object:check_enough_friendly(friendly) then
                LOG_ERROR("friendly:%d error:%s", friendly, errmsg(GAME_ERROR.friendly_not_enough))
                return GAME_ERROR.friendly_not_enough
            end
        end
        if self:get_storage_build(build_index) <= 0 then
            self.__role_object:consume_gold(gold,CONSUME_CODE.build)
            self.__role_object:consume_friendly(friendly,CONSUME_CODE.build)
            self.__role_object:get_achievement_ruler():cost_city_money(gold)
        end
    end
    local grid_object = self.new_grid_object(self,build_id,build_index,grid_id,flip,timestamp)
    grid_object:building_grid()
    local grid_type = grid_object:get_build_entry():get_build_type()
    if grid_type == 8 and self:get_storage_build(build_index) <= 0 then
        local gold = unlock_entry:get_gold()
        self.__role_object:get_achievement_ruler():decoration_money(gold)
        self.__role_object:get_daily_ruler():build_decorations()
        self.__role_object:get_daily_ruler():seven_decoration_count()
    elseif grid_type == 1 then
        self.__role_object:get_achievement_ruler():build_farmland()
    end
    local finish_time = grid_object:get_finish_time()
    if finish_time <= 0 and self:get_storage_build(build_index) <= 0 then
        local unlock_entry = self:get_unlock_entry(build_id)
        assert(unlock_entry,"unlock_entry is nil "..build_id)
        local build_exp = unlock_entry:get_product_exp()
        self.__role_object:add_exp(build_exp,SOURCE_CODE.finish)
    end
    if self:get_storage_build(build_index) > 0 then
        self.__storage_builds[build_index] = self:get_storage_build(build_index) - 1
    end
    self:add_grid_object(grid_object)
    return 0
end

function GridRuler:move_build(source_id,build_data)
    local grid_id = build_data.grid_id
    local flip = build_data.flip
    local grid_object = self.get_grid_object(self,source_id)
    assert(grid_object,"grid_object is nil")
    self.__grid_objects[source_id] = nil
    self.__grid_objects[grid_id] = grid_object
    grid_object:set_grid_id(grid_id)
    grid_object:set_flip(flip)
    return 0
end

function GridRuler:finish_build(build_id,timestamp,item_objects)
    item_objects = item_objects or {}
    local grid_object = self:get_build_object(build_id)
    assert(grid_object,"grid_object is nil")
    if not grid_object:check_can_finish(timestamp) then
        LOG_ERROR("error:%s", errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish 
    end
    local build_index = grid_object:get_build_index()
    local build_require = self:get_build_require(build_index)
    if not build_require then
        LOG_ERROR("error:%s", errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish 
    end
    local require_items = {}
    for i,v in ipairs(item_objects) do
        require_items[v.item_index] = v.item_count
    end
    local requires = build_require:get_require_formula()
    local cash = build_require:get_reward_cash()
    for k,v in pairs(requires) do
        if v ~= require_items[k] then
            LOG_ERROR("item_index:%d,item_count:%d,require_count:%d error:%s",k,require_items[k] or 0,v,errmsg(GAME_ERROR.number_not_match))
            return GAME_ERROR.number_not_match
        end
        if not self.__role_object:check_enough_item(k,v) then
            LOG_ERROR("item_index:%d,item_count:%d, error:%s",k,v,errmsg(GAME_ERROR.number_not_match))
            return GAME_ERROR.item_not_enough
        end
    end
    for k,v in pairs(requires) do
        self.__role_object:consume_item(k,v,CONSUME_CODE.build)
    end
    grid_object:finish_build()
    local grid_type = grid_object:get_build_entry():get_build_type()
    if grid_type == 3 then   --max_people
        local max_people = self.__role_object:get_people_ruler():get_max_people()
        self.__role_object:get_achievement_ruler():refresh_population_upper(max_people)
        self.__role_object:get_achievement_ruler():build_organization()
    elseif grid_type == 4 then  --people
        self.__role_object:get_achievement_ruler():build_house()
        local people = self.__role_object:get_people_ruler():get_people()
        self.__role_object:get_daily_ruler():seven_population(people)
    elseif grid_type == 2 then  --factory
        self.__role_object:get_achievement_ruler():finish_build_factory()
    end
    local unlock_entry = self:get_unlock_entry(build_id)
    assert(unlock_entry,"unlock_entry is nil "..build_id)
    local build_exp = unlock_entry:get_product_exp()
    self.__role_object:add_exp(build_exp,SOURCE_CODE.finish)
    self.__role_object:add_cash(cash,SOURCE_CODE.finish)
    return 0
end

function GridRuler:promote_build(build_id,timestamp,cash_count)
    local grid_object = self:get_build_object(build_id)
    assert(grid_object,"grid_object is nil")
    if not grid_object:check_can_promote() then
        LOG_ERROR("error:%s", errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote 
    end
    local create_time = grid_object:get_create_time()
    local build_index = grid_object:get_build_index()
    local build_require = self.get_build_require(self,build_index)
    local finish_time = grid_object:get_finish_time()
    local remain_time = create_time + finish_time - timestamp
    local cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if cash ~= cash_count then
        LOG_ERROR("cash:%d cash_count:%d error:%s",cash,cash_count,errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.number_not_match
    end
    if not self.__role_object:check_enough_cash(cash) then
        LOG_ERROR("cash:%d error:%s",cash,errmsg(GAME_ERROR.cash_not_enough))
        return GAME_ERROR.cash_not_enough 
    end
    grid_object:set_grid_promote()
    self.__role_object:consume_cash(cash,CONSUME_CODE.promote)
    return 0
end

function GridRuler:create_road_object(element_index,grid_id)
    self.__road_objects[grid_id] = element_index
    self.__role_object:get_achievement_ruler():create_road(1)
    return 0
end

function GridRuler:remove_road_object(grid_id)
    self.__road_objects[grid_id] = nil
    return 0
end

function GridRuler:create_green_object(element_index,grid_id)
    self.__green_objects[grid_id] = element_index
    return 0
end

function GridRuler:remove_green_object(grid_id)
    self.__green_objects[grid_id] = nil
    return 0
end

function GridRuler:create_floor_object(element_index,grid_id)
    self.__floor_objects[grid_id] = element_index
    return 0
end

function GridRuler:remove_floor_object(grid_id)
    self.__floor_objects[grid_id] = nil
    return 0
end

function GridRuler:open_undevelop_object(timestamp,grid_id)
    local undevelop_index = self.__undevelop_count + 1
    local undevelop_entry = self.__build_manager:get_undevelop_entry(undevelop_index)
    if not undevelop_entry then 
        LOG_ERROR("undevelop_index:%d  err:%s",undevelop_index,errmsg(GAME_ERROR.undevelop_not_exist))
        return GAME_ERROR.undevelop_not_exist
    end
    local formula = undevelop_entry:get_formula()
    for i,v in pairs(formula) do
        if not self.__role_object:check_enough_item(i,v) then
            LOG_ERROR("item_index:%d item_count:%d  err:%s",i,v,errmsg(GAME_ERROR.undevelop_not_exist))
            return GAME_ERROR.item_not_enough
        end
    end
    local people = undevelop_entry:get_people()
    local current_people = self.__role_object:get_people_ruler():get_people()
    if people > current_people then
        LOG_ERROR("people:%d current_people:%d  err:%s",people,current_people,errmsg(GAME_ERROR.people_not_enough))
        return GAME_ERROR.people_not_enough 
    end
    local gold = undevelop_entry:get_gold()
    if not self.__role_object:check_enough_gold(gold) then
        LOG_ERROR("gold:%d  err:%s",gold,errmsg(GAME_ERROR.gold_not_enough))
        return GAME_ERROR.gold_not_enough
    end
    for k,v in pairs(formula) do
        self.__role_object:consume_item(k,v,CONSUME_CODE.undevelop)
    end
    self.__role_object:consume_gold(gold,CONSUME_CODE.undevelop)
    local undevelop_object = UndevelopObject.new(self.__role_object,undevelop_index,timestamp,grid_id,grid_const.building)
    self.__building_undevelops[grid_id] = undevelop_object
    self.__undevelop_count = self.__undevelop_count + 1
    self.__role_object:get_daily_ruler():seven_open_undevelop(self.__undevelop_count)
    return 0
end

function GridRuler:finish_undevelop_object(timestamp,grid_id)
    local undevelop_object = self.__building_undevelops[grid_id]
    if not undevelop_object then
        LOG_ERROR("grid_id:%d  err:%s",grid_id,errmsg(GAME_ERROR.undevelop_not_exist))
        return GAME_ERROR.undevelop_not_exist
    end
    if not undevelop_object:check_can_finish(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_finish))
        return GAME_ERROR.cant_finish 
    end
    local exp = undevelop_object:get_finish_exp()
    self.__role_object:add_exp(exp,SOURCE_CODE.finish)
    self.__role_object:get_achievement_ruler():open_undevelop(1)
    self.__building_undevelops[grid_id] = nil
    self.__undevelop_objects[grid_id] = nil
    return 0
end

function GridRuler:promote_undevelop_object(timestamp,grid_id,cash_count)
    local undevelop_object = self.__building_undevelops[grid_id]
    if not undevelop_object then
        LOG_ERROR("grid_id:%d  err:%s",grid_id,errmsg(GAME_ERROR.undevelop_not_exist))
        return GAME_ERROR.undevelop_not_exist
    end
    if not undevelop_object:check_can_promote(timestamp) then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.cant_promote))
        return GAME_ERROR.cant_promote  
    end
    local remain_time = undevelop_object:get_remain_time(timestamp)
    local cash = self.__role_object:get_role_manager():get_time_cost(remain_time)
    if cash ~= cash_count then
        LOG_ERROR("cash:%d cash_count:%d error:%s",cash,cash_count,errmsg(GAME_ERROR.number_not_match))
        return GAME_ERROR.number_not_match 
    end
    self.__role_object:consume_cash(cash,CONSUME_CODE.promote)
    undevelop_object:promote_undevelop_object()
    return 0
end

function GridRuler:sell_build_object(grid_id)
    local grid_object = self:get_grid_object(grid_id)
    if not grid_object then
        LOG_ERROR("grid_id:%d error:%s", grid_id, errmsg(GAME_ERROR.building_not_exist))
        return GAME_ERROR.building_not_exist 
    end
    local build_index = grid_object:get_build_index()
    if build_index < 8000 then
        LOG_ERROR("build_index:%d error:%s", build_index, errmsg(GAME_ERROR.building_not_exist))
        return GAME_ERROR.building_not_exist 
    end
    local build_id = build_index * 1000 + 1
    local unlock_entry = self.get_unlock_entry(self,build_id) 
    if not unlock_entry then
        LOG_ERROR("build_id:%d error:%s", build_id, errmsg(GAME_ERROR.building_not_exist))
        return GAME_ERROR.building_not_exist 
    end
    local gold = unlock_entry:get_gold()
    self.__role_object:add_gold(gold,SOURCE_CODE.sale_item)
    self.__grid_objects[grid_id] = nil
    return 0
end

function GridRuler:get_storage_build(build_index)
    return self.__storage_builds[build_index] or 0
end

function GridRuler:storage_build(grid_id)
    local grid_object = self:get_grid_object(grid_id)
    if not grid_object then
        LOG_ERROR("grid_id:%d error:%s", grid_id, errmsg(GAME_ERROR.building_not_exist))
        return GAME_ERROR.building_not_exist 
    end
    local build_index = grid_object:get_build_index()
    if build_index < 8000 then
        LOG_ERROR("build_index:%d error:%s", build_index, errmsg(GAME_ERROR.building_not_exist))
        return GAME_ERROR.building_not_exist 
    end
    self.__storage_builds[build_index] = self:get_storage_build(build_index) + 1
    self.__grid_objects[grid_id] = nil
    return 0
end

return GridRuler