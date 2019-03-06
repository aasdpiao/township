local class = require "class"
local packer = require "db.packer"
local FriendObject = require "friend.friend_object"
local FriendDispatcher = require "friend.friend_dispatcher"
local skynet = require "skynet"
local FriendRuler = class()
local syslog = require "syslog"

local REFRESH_TIME = 2 * 60 * 60

function FriendRuler:ctor(role_object)
    self.__role_object = role_object
    self.__friend_objects = {}
    self.__recommend_objects = {}
    self.__request_friends = {}
    self.__verify_friends = {}
    self.__thumb_ups = {}
    self.__timestamp = 0
end

function FriendRuler:init()
    self.__friend_dispatcher = FriendDispatcher.new(self.__role_object)
    self.__friend_dispatcher:init()
end

function FriendRuler:load_friend_data(friend_data)
    if not friend_data then return end
    local code = packer.decode(friend_data)
    local friend_objects = code.friend_objects or {}
    local recommend_objects = code.recommend_objects or {}
    local request_friends = code.request_friends or {}
    local verify_friends = code.verify_friends or {}
    local timestamp = code.timestamp or 0
    local thumb_ups = code.thumb_ups or {}

    self:load_friend_objects(friend_objects)
    self:load_recommend_objects(recommend_objects)
    self:load_request_friends(request_friends)
    self:load_verify_friends(verify_friends)

    for i,v in ipairs(thumb_ups) do
        self.__thumb_ups[v.account_id] = 1
    end

    self.__role_object:get_cache_ruler():update_friends()
end

function FriendRuler:get_friend_object(account_id)
    return self.__friend_objects[account_id]
end

function FriendRuler:get_recommend_object(account_id)
    return self.__recommend_objects[account_id]
end

function FriendRuler:get_request_friend(account_id)
    return self.__request_friends[account_id]
end

function FriendRuler:get_verify_friend(account_id)
    return self.__verify_friends[account_id]
end

function FriendRuler:del_friend_object(account_id)
    self.__friend_objects[account_id] = nil
end

function FriendRuler:del_recommend_object(account_id)
    self.__recommend_objects[account_id] = nil
end

function FriendRuler:del_request_friend(account_id)
    self.__request_friends[account_id] = nil
end

function FriendRuler:del_verify_friend(account_id)
    self.__verify_friends[account_id] = nil
end

function FriendRuler:add_friend_object(account_id,friend_object)
    self.__friend_objects[account_id] = friend_object
    local friends_count = self:get_friend_count()
    self.__role_object:get_daily_ruler():seven_friends(friends_count)
end

function FriendRuler:add_recommend_object(account_id,friend_object)
    self.__recommend_objects[account_id] = friend_object
end

function FriendRuler:add_request_friend(account_id,friend_object)
    self.__request_friends[account_id] = friend_object
end

function FriendRuler:add_verify_friend(account_id,friend_object)
    self.__verify_friends[account_id] = friend_object
end

function FriendRuler:load_friend_objects(friend_objects)
    for i,v in ipairs(friend_objects) do
        local account_id = v.account_id
        local friend_object = FriendObject.new(account_id)
        self.__friend_objects[account_id] = friend_object
    end
end

function FriendRuler:load_recommend_objects(recommend_objects)
    for i,v in ipairs(recommend_objects) do
        local account_id = v.account_id
        local friend_object = FriendObject.new(account_id)
        self.__recommend_objects[account_id] = friend_object
    end
end

function FriendRuler:load_request_friends(request_friends)
    for i,v in ipairs(request_friends) do
        local account_id = v.account_id
        local friend_object = FriendObject.new(account_id)
        self.__request_friends[account_id] = friend_object
    end
end

function FriendRuler:load_verify_friends(verify_friends)
    for i,v in ipairs(verify_friends) do
        local account_id = v.account_id
        local friend_object = FriendObject.new(account_id)
        self.__verify_friends[account_id] = friend_object
    end
end

function FriendRuler:dump_friend_data()
    local friend_data = {}
    friend_data.friend_objects = self:dump_friend_objects()
    friend_data.recommend_objects = self:dump_recommend_objects()
    friend_data.request_friends = self:dump_request_friends()
    friend_data.verify_friends = self:dump_verify_friends()
    friend_data.thumb_ups = self:dump_thumb_ups()
    friend_data.timestamp = self.__timestamp
    return friend_data
end

function FriendRuler:get_update_friends()
    local friend_data = {}
    friend_data.friend_objects = self:dump_friend_objects()
    friend_data.recommend_objects = self:dump_recommend_objects()
    friend_data.request_friends = self:dump_request_friends()
    friend_data.verify_friends = self:dump_verify_friends()
    return friend_data
end

function FriendRuler:dump_friend_objects()
    local friend_objects = {}
    for k,v in pairs(self.__friend_objects) do
        table.insert(friend_objects,v:dump_friend_object())
    end
    return friend_objects
end

function FriendRuler:dump_recommend_objects()
    local recommend_objects = {}
    for k,v in pairs(self.__recommend_objects) do
        table.insert(recommend_objects,v:dump_friend_object())
    end
    return recommend_objects
end

function FriendRuler:dump_request_friends()
    local request_friends = {}
    for k,v in pairs(self.__request_friends) do
        table.insert(request_friends,v:dump_friend_object())
    end
    return request_friends
end

function FriendRuler:dump_verify_friends()
    local verify_friends = {}
    for k,v in pairs(self.__verify_friends) do
        table.insert(verify_friends,v:dump_friend_object())
    end
    return verify_friends
end

function FriendRuler:dump_thumb_ups()
    local thumb_ups = {}
    for k,v in pairs(self.__thumb_ups) do
        table.insert( thumb_ups, {account_id = k})
    end
    return thumb_ups
end

function FriendRuler:serialize_friend_data()
    local friend_data = self.dump_friend_data(self)
    return packer.encode(friend_data)
end

function FriendRuler:thumb_up(account_id)
    self.__thumb_ups[account_id] = 1
end

function FriendRuler:update_friends(friends)
    local friend_objects = friends.friend_objects or {}
    local recommend_objects = friends.recommend_objects or {}
    local request_friends = friends.request_friends or {}
    local verify_friends = friends.verify_friends or {}

    for i,v in ipairs(friend_objects) do
        local account_id = v.account_id
        local friend_object = self.__friend_objects[account_id]
        if friend_object then
            friend_object:update_friend(v)
        end
    end

    for i,v in ipairs(recommend_objects) do
        local account_id = v.account_id
        local friend_object = self.__recommend_objects[account_id]
        if friend_object then
            friend_object:update_friend(v)
        end
    end

    for i,v in ipairs(request_friends) do
        local account_id = v.account_id
        local friend_object = self.__request_friends[account_id]
        if friend_object then
            friend_object:update_friend(v)
        end
    end

    for i,v in ipairs(verify_friends) do
        local account_id = v.account_id
        local friend_object = self.__verify_friends[account_id]
        if friend_object then
            friend_object:update_friend(v)
        end
    end
end

function FriendRuler:del_friend(account_id)
    local friend_object = self:get_friend_object(account_id)
    if not friend_object then 
        LOG_ERROR("account_id:%d,err:%s",account_id,errmsg(GAME_ERROR.friend_not_exist))
        return GAME_ERROR.friend_not_exist
    end
    local result = self.__role_object:get_cache_ruler():del_friend(account_id)
    if result ~= 0 then return result end
    self.__friend_objects[account_id] = nil
    return 0
end

function FriendRuler:invite_friend(account_id)
    if self.__friend_objects[account_id] then return GAME_ERROR.friend_exist end
    local friend_object = self:get_recommend_object(account_id)
    if not friend_object then
        local cache_ruler = self.__role_object:get_cache_ruler()
        local check = cache_ruler:check_account_id(account_id)
        if check == 0 then return GAME_ERROR.friend_not_exist end
        local player = self.__role_object:get_cache_ruler():query_player(account_id)
        friend_object = FriendObject.new(account_id)
        friend_object:update_friend(player)
    end
    local result = self.__role_object:get_cache_ruler():invite_friend(account_id)
    if result ~= 0 then return result end
    self.__recommend_objects[account_id] = nil
    self.__request_friends[account_id] = friend_object
    self.__role_object:get_event_ruler():main_task_invite()
    return 0
end

function FriendRuler:request_recommend(timestamp)
    if self.__timestamp + REFRESH_TIME > timestamp then return end 
    self.__recommend_objects = {}
    local friends_list = {}
    for k,v in pairs(self.__friend_objects) do
        table.insert( friends_list, k)
    end
    for k,v in pairs(self.__request_friends) do
        table.insert( friends_list, k)
    end
    for k,v in pairs(self.__verify_friends) do
        table.insert( friends_list, k)
    end
    local friends =  self.__role_object:get_cache_ruler():request_recommend(friends_list)
    for i,v in ipairs(friends) do
        local account_id = v.account_id
        local friend_object = FriendObject.new(account_id)
        friend_object:update_friend(v)
        self.__recommend_objects[account_id] = friend_object
    end
    return self:dump_recommend_objects()
end

function FriendRuler:del_invite(account_id)
    local friend_object = self:get_request_friend(account_id)
    if not friend_object then 
        LOG_ERROR("account_id:%d err:%s",account_id,errmsg(GAME_ERROR.invite_exist))
        return GAME_ERROR.invite_exist
    end
    local result = self.__role_object:get_cache_ruler():del_invite(account_id)
    if result ~= 0 then return result end
    self:del_request_friend(account_id)
    return 0
end

function FriendRuler:del_verify(account_id)
    local friend_object = self:get_verify_friend(account_id)
    if not friend_object then 
        LOG_ERROR("account_id:%d err:%s",account_id,errmsg(GAME_ERROR.verify_exist))
        return GAME_ERROR.verify_exist
    end
    local result = self.__role_object:get_cache_ruler():del_verify(account_id)
    if result ~= 0 then return result end
    self:del_verify_friend(account_id)
    return 0
end

function FriendRuler:get_friend_count()
    local count = 0
    for k,v in pairs(self.__friend_objects) do
        count = count + 1
    end
    return count
end

function FriendRuler:accept_invite(account_id)
    local friend_object = self:get_verify_friend(account_id)
    if not friend_object then 
        LOG_ERROR("account_id:%d err:%s",account_id,errmsg(GAME_ERROR.verify_exist))
        return GAME_ERROR.verify_exist
    end
    local result = self.__role_object:get_cache_ruler():accept_invite(account_id)
    if result ~= 0 then return result end
    self:del_verify_friend(account_id)
    self:del_request_friend(account_id)
    self:del_recommend_object(account_id)
    self:add_friend_object(account_id,friend_object)
    return 0
end

function FriendRuler:check_thumb_up(account_id)
    return not self.__thumb_ups[account_id]
end

function FriendRuler:add_thumb_up_account_id(account_id)
    self.__thumb_ups[account_id] = 1
    self.__role_object:get_daily_ruler():thumb_up()
end

return FriendRuler