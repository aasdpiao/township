local class = require "class"
local WorkerBase = require "employment.worker_base"
local cjson = require "cjson"
local print_r = require "print_r"
local syslog =require "syslog"
local WorkerObject = class(WorkerBase)

function WorkerObject:ctor(role_object,worker_id)
    self.__role_object = role_object
    self.__worker_id = worker_id
    self.__worker_index = 0
    self.__level = 1
    self.__state = 1
    self.__exp = 0
    self.__profession = 0
    self.__skills = {}
    self.__worker_attr = {}
end

function WorkerObject:load_worker_object(worker_object)
    self.__worker_index = worker_object.worker_index
    self.__level = worker_object.level
    self.__state = worker_object.star
    self.__exp = worker_object.exp
    self.__profession = worker_object.profession
    local skills = worker_object.skills
    local worker_attr = worker_object.worker_attr
    self:load_worker_skills(skills)
    self:load_worker_attr(worker_attr)
end

function WorkerObject:dump_worker_object()
    local worker_object = {}
    worker_object.worker_id = self.__worker_id
    worker_object.worker_index = self.__worker_index
    worker_object.level = self.__level
    worker_object.star = self.__state
    worker_object.exp = self.__exp
    worker_object.profession = self.__profession
    worker_object.skills = self:dump_worker_skills()
    worker_object.worker_attr = self:dump_worker_attr()
    return worker_object
end

function WorkerObject:dump_worker_skills()
    local skills = {}
    for i,skill_index in ipairs(self.__skills) do
        table.insert( skills,{ skill_index = skill_index } )
    end
    return skills
end

function WorkerObject:dump_worker_attr()
    return cjson.encode(self.__worker_attr)
end

function WorkerObject:load_worker_skills(skills)
    for k,v in ipairs(skills) do
        table.insert(self.__skills,v.skill_index)
    end
end

function WorkerObject:set_worker_skills(skills)
    self.__skills = skills
end

function WorkerObject:get_valid_skills()
    local employment_manager = self.__role_object:get_employment_ruler():get_employment_manager()
    local skills = {}
    local skill_index1 = self.__skills[1]
    local skill_index2 = self.__skills[2]
    local skill_entry1 = employment_manager:get_woker_skill(skill_index1)
    local skill_entry2 = employment_manager:get_woker_skill(skill_index2)
    if self.__state >= 3 then
        local item_index = skill_entry1:get_skill_item()
        local item_count = skill_entry1:get_skill_formula()
        skills[item_index] = item_count
    elseif self.__state >= 5 then
        local item_index = skill_entry2:get_skill_item()
        local item_count = skill_entry2:get_skill_formula()
        skills[item_index] = item_count
    end 
    return skills
end

function WorkerObject:load_worker_attr(encode_data)
    if not encode_data then return end
    self.__worker_attr = cjson.decode(encode_data)
end

function WorkerObject:set_worker_attr(key,value)
    self.__worker_attr[key] = value
end

function WorkerObject:get_worker_attr(key,default)
    return self.__worker_attr[key] or default
end

function WorkerObject:set_build_id(build_id)
    self:set_worker_attr("build_id",build_id)
end

function WorkerObject:get_build_id()
    return self:get_worker_attr("build_id",0)
end

function WorkerObject:get_accelerate()
    local employment_manager = self.__role_object:get_employment_ruler():get_employment_manager()
    local worker_levelup_entry = employment_manager:get_levelup_entry(self.__level)
    if not worker_levelup_entry then return 0 end
    return worker_levelup_entry:get_accelerate()
end

function WorkerObject:get_off_work()
    self:set_build_id()
end

function WorkerObject:debug_info()
    local worker_info = ""
    worker_info = worker_info.."worker_id:"..self.__worker_id.."\n"
    worker_info = worker_info.."worker_index:"..self.__worker_index.."\n"
    worker_info = worker_info.."level:"..self.__level.."\n"
    worker_info = worker_info.."star:"..self.__state.."\n"
    worker_info = worker_info.."exp:"..self.__exp.."\n"
    worker_info = worker_info.."profession:"..self.__profession.."\n"
    worker_info = worker_info.."skills:"..cjson.encode(self.__skills).."\n"
    worker_info = worker_info.."worker_attr:"..cjson.encode(self.__worker_attr).."\n"
    return worker_info
end

return WorkerObject