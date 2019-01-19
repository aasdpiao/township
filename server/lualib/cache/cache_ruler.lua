local class = require "class"
local cjson = require "cjson"
local skynet = require "skynet"
local CacheDispatcher = require "cache.cache_dispatcher"

local CacheRuler = class()

function CacheRuler:ctor(role_object)
    self.__role_object = role_object

end

function CacheRuler:init()
    self.__cache_dispatcher = CacheDispatcher.new(self.__role_object)
    self.__cache_dispatcher:init()
end

function CacheRuler:handle_request(...)
    return self.__cache_dispatcher:dispatcher_msg(...)
end

function CacheRuler:update_friends()
    local friends = self.__role_object:get_friend_ruler():get_update_friends()
    local update_friends = skynet.call("recommend","lua","update_friends",friends)
    self.__role_object:get_friend_ruler():update_friends(update_friends)
end

function CacheRuler:query_player(account_id)
    local player = skynet.call("recommend","lua","query_player",account_id)
    return cjson.decode(player)
end

function CacheRuler:query_address(account_id)
    local agent_address = skynet.call("gamed","lua","query_address",account_id)
    return agent_address
end

function CacheRuler:check_account_id(account_id)
    local sql = "call check_account_id("..account_id..")"
    local ret = skynet.call("mysqld","lua","queryaccountdb",sql)
    return ret[1][1][1]
end

function CacheRuler:access_manor(account_id)
    if self:check_account_id(account_id) == 0 then
        LOG_ERROR("account_id:%d err:%s",account_id,errmsg(GAME_ERROR.friend_not_exist))
        return GAME_ERROR.friend_not_exist 
    end
    local agent_address = self:query_address(account_id)
    self.__role_object:get_daily_ruler():access_manor()
    return skynet.call(agent_address,"lua","handle_request","access_manor")
end

function CacheRuler:del_friend(account_id)
    local agent_address = self:query_address(account_id)
    return skynet.call(agent_address,"lua","handle_request","del_friend",self.__role_object:get_account_id())
end

function CacheRuler:invite_friend(account_id)
    local agent_address = self:query_address(account_id)
    return skynet.call(agent_address,"lua","handle_request","invite_friend",self.__role_object:get_account_id())
end

function CacheRuler:request_recommend(friends_list)
    local account_id = self.__role_object:get_account_id()
    return skynet.call("recommend","lua","recommend_friends",account_id,friends_list)
end

function CacheRuler:del_invite(account_id)
    local agent_address = self:query_address(account_id)
    return skynet.call(agent_address,"lua","handle_request","del_invite",self.__role_object:get_account_id())
end

function CacheRuler:del_verify(account_id)
    local agent_address = self:query_address(account_id)
    return skynet.call(agent_address,"lua","handle_request","del_verify",self.__role_object:get_account_id())
end

function CacheRuler:accept_invite(account_id)
    local agent_address = self:query_address(account_id)
    return skynet.call(agent_address,"lua","handle_request","accept_invite",self.__role_object:get_account_id())
end

function CacheRuler:finish_trains_help(account_id,timestamp,order_object)
    local agent_address = self:query_address(account_id)
    return skynet.call(agent_address,"lua","handle_request","finish_trains_help",self.__role_object:get_account_id(),timestamp,order_object)
end

function CacheRuler:finish_flight_help(account_id,timestamp,row,column)
    local agent_address = self:query_address(account_id)
    return skynet.call(agent_address,"lua","handle_request","finish_flight_help",self.__role_object:get_account_id(),timestamp,row,column)
end

function CacheRuler:watering(account_id,build_id,timestamp)
    local agent_address = self:query_address(account_id)
    return skynet.call(agent_address,"lua","handle_request","watering",self.__role_object:get_account_id(),build_id,timestamp)
end

return CacheRuler