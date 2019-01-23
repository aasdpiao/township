local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"
local cjson = require "cjson"

local FriendDispatcher = class()

function FriendDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function FriendDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function FriendDispatcher:init()
    self:register_c2s_callback("del_friend",self.dispatcher_del_friend)
    self:register_c2s_callback("invite_friend",self.dispatcher_invite_friend)
    self:register_c2s_callback("request_recommend",self.dispatcher_request_recommend)
    self:register_c2s_callback("del_invite",self.dispatcher_del_invite)
    self:register_c2s_callback("del_verify",self.dispatcher_del_verify)
    self:register_c2s_callback("accept_invite",self.dispatcher_accept_invite)
    self:register_c2s_callback("access_manor",self.dispatcher_access_manor)
    self:register_c2s_callback("thumb_up_friend",self.dispatcher_thumb_up_friend)
    self:register_c2s_callback("exit_manor",self.dispatcher_exit_manor)
end

function FriendDispatcher.dispatcher_exit_manor(role_object,msg_data)
    role_object:unsubscribe()
    return {result = 0}
end

function FriendDispatcher.dispatcher_thumb_up_friend(role_object,msg_data)
    local account_id = msg_data.account_id
    if not account_id then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.parameter_invalid))
        return {result = GAME_ERROR.parameter_invalid}
    end
    local friend_ruler = role_object:get_friend_ruler()
    if not friend_ruler:check_thumb_up(account_id) then
        LOG_ERROR("account_id:%d,err:%s",account_id,errmsg(GAME_ERROR.thumb_up_exist))
        return {result = GAME_ERROR.thumb_up_exist}
    end
    friend_ruler:add_thumb_up_account_id(account_id)
    local thumb_up = skynet.call("redisd","lua","thumb_up",account_id)
    return {result = 0,thumb_up = thumb_up}
end

function FriendDispatcher.dispatcher_del_friend(role_object,msg_data)
    local account_id = msg_data.account_id
    if not account_id then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.parameter_invalid))
        return {result = GAME_ERROR.parameter_invalid}
    end
    local result = role_object:get_friend_ruler():del_friend(account_id)
    return {result = result}
end

function FriendDispatcher.dispatcher_invite_friend(role_object,msg_data)
    local account_id = msg_data.account_id
    if not account_id then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.parameter_invalid))
        return {result = GAME_ERROR.parameter_invalid}
    end
    local result = role_object:get_friend_ruler():invite_friend(account_id)
    local friend_object = role_object:get_friend_ruler():get_request_friend(account_id)
    if not friend_object then 
        result = GAME_ERROR.friend_not_exist
    else
        friend_object = friend_object:dump_friend_object()
    end
    return {result = result,friend_object = friend_object}
end

function FriendDispatcher.dispatcher_request_recommend(role_object,msg_data)
    local timestamp = msg_data.timestamp
    if not timestamp then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.parameter_invalid))
        return {result = GAME_ERROR.parameter_invalid}
    end
    local recommend_friends = role_object:get_friend_ruler():request_recommend(timestamp)
    return {result = 0,recommend_objects = recommend_friends}
end

function FriendDispatcher.dispatcher_del_invite(role_object,msg_data)
    local account_id = msg_data.account_id
    if not account_id then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.parameter_invalid))
        return {result = GAME_ERROR.parameter_invalid}
    end
    local result = role_object:get_friend_ruler():del_invite(account_id)
    return {result = result}
end

function FriendDispatcher.dispatcher_del_verify(role_object,msg_data)
    local account_id = msg_data.account_id
    if not account_id then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.parameter_invalid))
        return {result = GAME_ERROR.parameter_invalid}
    end
    local result = role_object:get_friend_ruler():del_verify(account_id)
    return {result = result}
end

function FriendDispatcher.dispatcher_accept_invite(role_object,msg_data)
    local account_id = msg_data.account_id
    if not account_id then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.parameter_invalid))
        return {result = GAME_ERROR.parameter_invalid}
    end
    local result = role_object:get_friend_ruler():accept_invite(account_id)
    return {result = result}
end

function FriendDispatcher.dispatcher_access_manor(role_object,msg_data)
    local account_id = msg_data.account_id
    if not account_id then
        LOG_ERROR("err:%s",errmsg(GAME_ERROR.parameter_invalid))
        return {result = GAME_ERROR.parameter_invalid}
    end
    local player,subscribe_channel = role_object:get_cache_ruler():access_manor(account_id)
    role_object:subscribe(account_id,subscribe_channel)
    return player
end

return FriendDispatcher
