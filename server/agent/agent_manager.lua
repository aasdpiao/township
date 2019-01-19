local class = require "class"
local skynet = require "skynet"
local AgentObject = require "agent_object"

local AgentManager = class()

function AgentManager:ctor()
    self.__agent_pool = {}
    self.__agent_objects = {}
    self.__username_map = {}
end

function AgentManager:new_role_agnet(account_id,username)
    if #self.__agent_pool > 0 then
        local agent_object = table.remove( self.__agent_pool )
        agent_object:set_account_id(account_id)
        agent_object:set_username(username)
        self.__agent_objects[account_id] = agent_object
        self.__username_map[username] = agent_object
        agent_object:active_auto_save()
		return agent_object
    else
        local agent = skynet.newservice "role_agent"
        local agent_object = AgentObject.new(agent,account_id,username)
        self.__agent_objects[account_id] = agent_object
        self.__username_map[username] = agent_object
        agent_object:active_auto_save()
		return agent_object
	end
end

function AgentManager:get_online_agent_objects()
    local online_agent_objects = {}
    for account_id,agent_object in pairs(self.__agent_objects) do
        if not agent_object:get_offline() then
            table.insert( online_agent_objects, agent_object )
        end
    end
    return online_agent_objects
end

function AgentManager:get_offline_agent_objects()
    local offline_agent_objects = {}
    for account_id,agent_object in pairs(self.__agent_objects) do
        if agent_object:get_offline() then
            table.insert( offline_agent_objects, agent_object )
        end
    end
    return offline_agent_objects
end

function AgentManager:get_agent_object(account_id)
    return self.__agent_objects[account_id]
end

function AgentManager:recycle_role_object(agent_object)
    agent_object:deactive_auto_save()
    self.__agent_objects[agent_object:get_account_id()] = nil
    self.__username_map[agent_object:get_username()] = nil
	table.insert(self.__agent_pool,agent_object)
end

function AgentManager:role_agent_logout(agent_object)
    agent_object:set_offline(false)
end

function AgentManager:get_agent_object_by_username(username)
    return self.__username_map[username]
end

return AgentManager