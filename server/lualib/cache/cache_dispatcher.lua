local syslog = require "syslog"
local class = require "class"
local skynet = require "skynet"
local FriendObject = require "friend.friend_object"

local CacheDispatcher = class()

function CacheDispatcher:ctor(role_object)
    self.__role_object = role_object
    self.__cmd = {}
end

function CacheDispatcher:register_command_handle(command,handle)
    self.__cmd[command] = handle
end

function CacheDispatcher:dispatcher_msg(command,...)
    if not self.__cmd[command] then LOG_ERROR("command:%s not exits",command) return end
    return self.__cmd[command](self,...)
end

function CacheDispatcher:init()
    self:register_command_handle("del_friend",self.dispatcher_del_friend)
    self:register_command_handle("invite_friend",self.dispatcher_invite_friend)
    self:register_command_handle("del_invite",self.dispatcher_del_invite)
    self:register_command_handle("del_verify",self.dispatcher_del_verify)
    self:register_command_handle("accept_invite",self.dispatcher_accept_invite)
    self:register_command_handle("finish_trains_help",self.dispatcher_finish_trains_help)
    self:register_command_handle("access_manor",self.dispatcher_access_manor)
    self:register_command_handle("finish_flight_help",self.dispatcher_finish_flight_help)
    self:register_command_handle("watering",self.dispatcher_watering)
end

function CacheDispatcher:dispatcher_watering(account_id,build_id,timestamp)
    local plant_ruler = self.__role_object:get_plant_ruler()
    return plant_ruler:watering(account_id,build_id,timestamp)
end

function CacheDispatcher:dispatcher_finish_flight_help(account_id,timestamp,row,column)
    local flight_ruler = self.__role_object:get_flight_ruler()
    return flight_ruler:finish_flight_help(account_id,timestamp,row,column)
end

function CacheDispatcher:dispatcher_access_manor()
    local account_id = self.__role_object:get_account_id()
    local town_name = self.__role_object:get_town_name()
    local level = self.__role_object:get_level()
    local exp = self.__role_object:get_exp()
    local thumb_up = self.__role_object:get_thumb_up()
    local avatar_index = self.__role_object:get_avatar_index()

    local grid_data = self.__role_object:get_grid_ruler():dump_grid_data()
    local plant_data = self.__role_object:get_plant_ruler():dump_plant_data()
    local factory_data = self.__role_object:get_factory_ruler():dump_factory_data()
    local feed_data = self.__role_object:get_feed_ruler():dump_feed_data()
    local trains_data = self.__role_object:get_trains_ruler():dump_trains_data()
    local seaport_data = self.__role_object:get_seaport_ruler():dump_seaport_data()
    local flight_data = self.__role_object:get_flight_ruler():dump_flight_data()
    local helicopter_data = self.__role_object:get_helicopter_ruler():dump_helicopter_data()
    local employment_data = self.__role_object:get_employment_ruler():dump_employment_data()
    local friend_data = self.__role_object:get_friend_ruler():dump_friend_data()

    local player = {}
    player.account_id = account_id
    player.town_name = town_name
    player.level = level
    player.exp = exp
    player.thumb_up = thumb_up
    player.avatar_index = avatar_index
    player.grid_data = grid_data
    player.plant_data = plant_data
    player.feed_data = feed_data
    player.factory_data = factory_data
    player.trains_data = trains_data
    player.seaport_data = seaport_data
    player.flight_data = flight_data
    player.helicopter_data = helicopter_data
    player.employment_data = employment_data
    player.friend_data = friend_data
    return player
end

function CacheDispatcher:dispatcher_finish_trains_help(account_id,trains_index,order_object)
    local trains_ruler = self.__role_object:get_trains_ruler()
    return trains_ruler:finish_trains_help(account_id,trains_index,order_object)
end

function CacheDispatcher:dispatcher_del_friend(account_id)
    local friend_object = self.__role_object:get_friend_ruler():get_friend_object(account_id)
    if not friend_object then return GAME_ERROR.friend_not_exist end
    self.__role_object:get_friend_ruler():del_friend_object(account_id)
    self.__role_object:send_request("del_friend",{account_id = account_id})
    LOG_INFO("%d 删除 %d 好友成功",account_id,self.__role_object:get_account_id())
    return 0
end

function CacheDispatcher:dispatcher_invite_friend(account_id)
    local friend_object = self.__role_object:get_friend_ruler():get_friend_object(account_id)
    if friend_object then 
        LOG_ERROR("account_id:%d err:%s",account_id,errmsg(GAME_ERROR.friend_exist))
        return GAME_ERROR.friend_exist 
    end
    if self.__role_object:get_cache_ruler():check_account_id(account_id) == 0 then
        LOG_ERROR("account_id:%d err:%s",account_id,errmsg(GAME_ERROR.friend_not_exist))
        return GAME_ERROR.friend_not_exist
    end
    local player = self.__role_object:get_cache_ruler():query_player(account_id)
    local friend_object = FriendObject.new(account_id)
    friend_object:update_friend(player)
    self.__role_object:get_friend_ruler():add_verify_friend(account_id,friend_object)
    local data = friend_object:dump_friend_object()
    self.__role_object:send_request("invite_friend",{friend_object = data})
    LOG_INFO("%d 邀请 %d 好友成功",account_id,self.__role_object:get_account_id())
    return 0
end

function CacheDispatcher:dispatcher_del_invite(account_id)
    local friend_ruler = self.__role_object:get_friend_ruler()
    local friend_object = friend_ruler:get_verify_friend(account_id)
    if not friend_object then 
        LOG_ERROR("account_id:%d err:%s",account_id,errmsg(GAME_ERROR.invite_exist))
        return GAME_ERROR.invite_exist 
    end
    friend_ruler:del_verify_friend(account_id)
    self.__role_object:send_request("del_invite",{account_id = account_id})
    LOG_INFO("%d 删除 %d 好友邀请",account_id,self.__role_object:get_account_id())
    return 0
end

function CacheDispatcher:dispatcher_del_verify(account_id)
    local friend_ruler = self.__role_object:get_friend_ruler()
    local friend_object = friend_ruler:get_request_friend(account_id)
    if not friend_object then 
        LOG_ERROR("account_id:%d err:%s",account_id,errmsg(GAME_ERROR.verify_exist))
        return GAME_ERROR.verify_exist 
    end
    friend_ruler:del_request_friend(account_id)
    self.__role_object:send_request("del_verify",{account_id = account_id})
    LOG_INFO("%d 删除 %d 好友验证",account_id,self.__role_object:get_account_id())
    return 0
end

function CacheDispatcher:dispatcher_accept_invite(account_id)
    local friend_ruler = self.__role_object:get_friend_ruler()
    local friend_object = friend_ruler:get_request_friend(account_id)
    if not friend_object then 
        LOG_ERROR("account_id:%d err:%s",account_id,errmsg(GAME_ERROR.verify_exist))
        return GAME_ERROR.verify_exist 
    end
    friend_ruler:del_request_friend(account_id)
    friend_ruler:del_verify_friend(account_id)
    friend_ruler:del_recommend_object(account_id)
    friend_ruler:add_friend_object(account_id,friend_object)
    self.__role_object:send_request("accept_invite",{account_id = account_id})
    LOG_INFO("%d 接受 %d 好友验证",account_id,self.__role_object:get_account_id())
    return 0
end

return CacheDispatcher