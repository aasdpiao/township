local class = require "class"

local FriendObject = class()

function FriendObject:ctor(account_id)
    self.__account_id = account_id
    self.__avatar_index = 0
    self.__level = 0
    self.__town_name = ""
    self.__status = 0
end

function FriendObject:dump_friend_object()
    local friend_object = {}
    friend_object.account_id = self.__account_id
    friend_object.avatar_index = self.__avatar_index
    friend_object.level = self.__level
    friend_object.town_name = self.__town_name
    return friend_object
end

function FriendObject:update_friend(friend_object)
    self.__avatar_index = friend_object.avatar_index
    self.__level = friend_object.level
    self.__town_name = friend_object.town_name
end

function FriendObject:set_status(status)
    self.__status = status
end

function FriendObject:get_status()
    return self.__status
end

return FriendObject