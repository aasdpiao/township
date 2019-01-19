local class = require "class"
local ItemObject = require "item.item_object"
local ItemManager = require "item.item_manager"
local packer = require "db.packer"
local ItemRuler = class()

function ItemRuler:ctor(role_object)
    self.__role_object = role_object
    self.__item_objects = {}
    self.__worker_id = 0
    self.__expand_count = 0
    self.__item_capacity = 50
    self.__item_count = 0
end

function ItemRuler:init()
    self.__item_manager = ItemManager.new()
    self.__item_manager:init()
end

function ItemRuler:get_item_manager()
    return self.__item_manager
end

function ItemRuler:get_item_entry(item_index)
    return self.__item_manager:get_item_entry(item_index)
end

function ItemRuler:load_item_data(item_data)
    if not item_data then return end
    self.__item_objects = {}
    self.__item_count = 0
    self.__item_capacity = 50
    local code = packer.decode(item_data)
    local item_objects = code.item_objects or {}
    local worker_id = code.worker_id or 0
    local expand_count = code.expand_count or 0
    for k,v in ipairs(item_objects) do
        local item_index = v.item_index
        local item_count = v.item_count
        local item_object = self.add_item_count(self,item_index,item_count)
    end
    self.__worker_id = worker_id
    self.__expand_count = expand_count
    local expand_entry = self.__item_manager:get_expand_entry(expand_count)
    if not expand_entry then return end
    self.__item_capacity = expand_entry:get_item_capacity()
end

function ItemRuler:dump_item_data()
    local item_data = {}
    item_data.worker_id = self.__worker_id
    item_data.expand_count = self.__expand_count
    item_data.item_objects = {}
    for k,v in pairs(self.__item_objects) do
        local item_object = v:dump_item_object()
        table.insert( item_data.item_objects, item_object )
    end
    return item_data
end

function ItemRuler:serialize_item_data()
    local item_data = self.dump_item_data(self)
    return packer.encode(item_data)
end

function ItemRuler:check_can_add_worker(timestamp)
    return self.__worker_id <= 0
end

function ItemRuler:employment_worker_object(worker_id,timestamp)
    if not self:check_can_add_worker(timestamp) then
        LOG_ERROR("worker_id:%d timestamp:%s error:%s",worker_id,get_epoch_time(timestamp),errmsg(GAME_ERROR.cant_add_worker))
        return GAME_ERROR.cant_add_worker
    end
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(worker_id)
    assert(worker_object,"worker_object is nil")
    self.__worker_id = worker_id
    worker_object:set_build_id(5004001)
    return 0
end

function ItemRuler:get_off_work(timestamp)
    local worker_object = self.__role_object:get_employment_ruler():get_worker_object(self.__worker_id)
    if not worker_object then
        LOG_ERROR("timestamp:%s error:%s",get_epoch_time(timestamp),errmsg(GAME_ERROR.worker_not_exist))
        return GAME_ERROR.worker_not_exist 
    end
    self.__worker_id = 0
    worker_object:get_off_work()
    return 0
end

function ItemRuler:get_expand_count()
    return self.__expand_count
end

function ItemRuler:get_require_items()
    return self.__item_manager:get_expand_entry(self.__expand_count):get_item_objects()
end

function ItemRuler:check_can_add_slot(slot_index)
    if self.__expand_count + 1 ~= slot_index then return false end
    return slot_index <= 99
end

function ItemRuler:set_expand_count(expand_count)
    self.__expand_count = expand_count
    local expand_entry = self.__item_manager:get_expand_entry(expand_count)
    self.__item_capacity = expand_entry:get_item_capacity()
end

function ItemRuler:get_item_object(item_index)
    return self.__item_objects[item_index]
end

function ItemRuler:create_item_object(item_index)
    local item_entry = self.get_item_entry(self,item_index)
    assert(item_entry,"item_entry is nil")
    local item_object = ItemObject.new(item_entry)
    return item_object
end

function ItemRuler:add_item_object(item_object)
    local item_index = item_object:get_item_index()
    self.__item_objects[item_index] = item_object
end

function ItemRuler:add_item_count(item_index,item_count)
    item_count = item_count or 1
    local item_object = self.get_item_object(self,item_index)
    if not item_object then
        item_object = self.create_item_object(self,item_index)
        item_object:set_item_count(item_count)
        self.add_item_object(self,item_object)
    else
        item_object:add_item_count(item_count)
    end
    self.__item_count = self.__item_count + item_count
    return item_object
end

function ItemRuler:consume_item_count(item_index,item_count)
    if not self.check_enough_item_count(self,item_index,item_count) then return false end
    local item_object = self.get_item_object(self,item_index)
    local count = item_object:get_item_count()
    item_object:set_item_count(count - item_count)
    if item_object:get_item_count() <= 0 then
        self.remove_item_object(self,item_object)
    end
    self.__item_count = self.__item_count - item_count
end

function ItemRuler:remove_item_object(item_object)
    self.__item_objects[item_object:get_item_index()] = nil
end

function ItemRuler:check_enough_item_count(item_index,item_count)
    local item_object = self.get_item_object(self,item_index)
    if not item_object then return false end
    return item_object:get_item_count() >= item_count
end

function ItemRuler:check_item_capacity(item_count)
    return self.__item_capacity >= self.__item_count + item_count
end

function ItemRuler:get_item_cash(item_objects)
    local cash_count = 0
    for item_index,item_count in pairs(item_objects) do
        local item_entry = self:get_item_entry(item_index)
        cash_count = cash_count + item_entry:get_cash_count() * item_count
    end
    return cash_count
end

function ItemRuler:debug_info()
    local item_info = ""
    for k,item_object in pairs(self.__item_objects) do
        item_info = item_info..item_object:debug_info().."\n"
    end
    return item_info
end

return ItemRuler