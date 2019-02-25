local class = require "class"
local datacenter = require "skynet.datacenter"
local WorkerEntry = require "employment.worker_entry"
local Workerprofession = require "employment.worker_profession"
local WorkerSkill = require "employment.worker_skill"
local LevelupEntry = require "employment.levelup_entry"
local EmployEntry = require "employment.employ_entry"
local WorkerObject = require "employment.worker_object"
local WorkerState = require "employment.worker_state"
local utils = require "utils"
local print_r = require "print_r"
local syslog = require "syslog"

local EmploymentManager = class()

function EmploymentManager:ctor(role_object)
    self.__role_object = role_object
    self.__worker_entrys = {}
    self.__woker_professions = {}
    self.__woker_skills = {}
    self.__levelup_entrys = {}
    self.__employ_entrys = {}
    self.__worker_states = {}

    self.__profession_workers = {}
end

function EmploymentManager:init()
    self:load_worker_config()
    self:load_worker_profession()
    self:load_worker_skill()
    self:load_levelup_config()
    self:load_state_config()
    self:load_employ_config()
end

function EmploymentManager:load_state_config()
    local state_config = datacenter.get("worker_starup")
    for k,state in pairs(state_config) do
        local profession = state.profession_index
        local state_index = state.star_id
        local worker_state = WorkerState.new(state)
        if not self.__worker_states[profession] then self.__worker_states[profession] = {} end
        self.__worker_states[profession][state_index] = worker_state
    end
end

function EmploymentManager:get_worker_state(profession,state)
    return self.__worker_states[profession][state]
end

function EmploymentManager:get_employ_entry(employ_index)
    return self.__employ_entrys[employ_index]
end

function EmploymentManager:load_employ_config()
    local employ_config = datacenter.get("employ_config")
    for k,employ in pairs(employ_config) do
        local employ_index = employ.employ_index
        local employ_entry = EmployEntry.new(employ)
        self.__employ_entrys[employ_index] = employ_entry
    end
end

function EmploymentManager:get_levelup_entry(level)
    return self.__levelup_entrys[level]
end

function EmploymentManager:load_levelup_config()
    local worker_levelup = datacenter.get("worker_levelup")
    for k,levelup_config in pairs(worker_levelup) do
        local worker_level = levelup_config.worker_level
        local levelup_entry = LevelupEntry.new(levelup_config)
        self.__levelup_entrys[worker_level] = levelup_entry
    end
end

function EmploymentManager:get_worker_entry(worker_index)
    return self.__worker_entrys[worker_index]
end

function EmploymentManager:load_worker_config()
    local worker_config = datacenter.get("worker_config")
    for k,worker_data in pairs(worker_config) do
        local worker_index = worker_data.worker_index
        local worker_entry = WorkerEntry.new(worker_data)
        self.__worker_entrys[worker_index] = worker_entry
    end
    for worker_index,worker_entry in pairs(self.__worker_entrys) do
        local professions = worker_entry:get_professions()
        for i,v in ipairs(professions) do
            if not self.__profession_workers[v] then self.__profession_workers[v] = {} end
            table.insert(self.__profession_workers[v],worker_index)
        end
    end
end

function EmploymentManager:get_worker_profession(profession_index)
    return self.__woker_professions[profession_index]
end

function EmploymentManager:load_worker_profession()
    local worker_profession_config = datacenter.get("worker_profession")
    for k,profession_config in pairs(worker_profession_config) do
        local profession_index = profession_config.profession_index
        local woker_profession = Workerprofession.new(profession_config)
        self.__woker_professions[profession_index] = woker_profession
    end
end

function EmploymentManager:get_woker_skill(skill_index)
    return self.__woker_skills[skill_index]
end

function EmploymentManager:load_worker_skill()
    local woker_skill_config = datacenter.get("worker_skill")
    for k,skill_config in pairs(woker_skill_config) do
        local skill_index = skill_config.skill_index
        local woker_skill = WorkerSkill.new(skill_config)
        self.__woker_skills[skill_index] = woker_skill
    end
end

function EmploymentManager:gen_worker_index(profession)
    local worker_indexs = self.__profession_workers[profession]
    local count = #worker_indexs
    local seed = utils.get_random_int(1,count)
    return worker_indexs[seed]
end

function EmploymentManager:gen_worker_object(employ_index,worker_id)
    local employ_entry = self:get_employ_entry(employ_index)
    if not employ_entry then return end
    local employ_config = employ_entry:get_worker_object()
    local worker_object = WorkerObject.new(self.__role_object,worker_id)
    local state = employ_config.state
    local profession = employ_config.profession
    worker_object:set_worker_state(state)
    local level = (state - 1) * 5 + utils.get_random_int(1,5)
    worker_object:set_worker_level(level)
    worker_object:set_worker_profession(profession)
    local worker_index = self:gen_worker_index(profession)
    worker_object:set_worker_index(worker_index)
    return worker_object
end

function EmploymentManager:get_worker_skills(profession)
    local profession_entry = self:get_worker_profession(profession)
    if not profession_entry then return end
    local role_level = self.__role_object:get_level()
    local profession_skills = profession_entry:get_profession_skills() 
    local skills_weight = profession_entry:get_skills_weight() 
    local total_weight = 0
    local value_weight_list = {}
    for i,skill_index in ipairs(profession_skills) do
        local skill_entry = self:get_woker_skill(skill_index)
        if skill_entry and skill_entry:check_unlock(role_level) then
            local skill_weight = skills_weight[i]
            local skill_element = {skill_index,skill_weight}
            table.insert( value_weight_list, skill_element)
            total_weight = total_weight + skill_weight
        end
    end
    return utils.get_random_list_in_weight(total_weight,value_weight_list,2)
end

return EmploymentManager