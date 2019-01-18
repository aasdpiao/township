local class = require "class"
local skynet = require "skynet"

local AgentObject = class()

function AgentObject:ctor(agent,account_id,username)
    self.__agent = agent
    self.__account_id = account_id
    self.__username = username
    self.__offline = false
end

function AgentObject:set_offline(offline)
    self.__offline = offline
end

function AgentObject:get_offline()
    return self.__offline
end

function AgentObject:get_account_id()
    return self.__account_id
end

function AgentObject:set_account_id(account_id)
    self.__account_id = account_id
end

function AgentObject:get_username()
    return self.__username
end

function AgentObject:set_username(username)
    self.__username = username
end

function AgentObject:get_agent()
    return self.__agent
end

function AgentObject:active_auto_save()
    skynet.call(self.__agent,"lua","active_auto_save")
end

function AgentObject:deactive_auto_save()
    skynet.call(self.__agent,"lua","deactive_auto_save")
end

return AgentObject