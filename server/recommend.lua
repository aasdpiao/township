local skynet = require "skynet"
local cjson = require "cjson"
local redis = require "skynet.db.redis"
local syslog =require "syslog"
require "skynet.manager"

cjson.encode_sparse_array(true, 1, 1)

local connect
local CMD = {}

function CMD.start()
    connect = redis.connect{
        host = skynet.getenv("redis_host"),
        port = skynet.getenv("redis_port"),
        db = 1,
        auth = skynet.getenv("redis_auth"),
    }
    if connect then
        connect:flushdb()
    else
        skynet.error("redis connect error")
    end
	local sql = "call load_friends()" 
    local ret =skynet.call("mysqld","lua","querygamedb",sql)
    local friends = ret[1]
    if not friends then return end
    for i,v in ipairs(friends) do
        local account_id = v[1]
        local town_name = v[2]
        local level = v[3]
        local exp = v[4]
        local avatar_index = v[5]
        if level == 1 and exp == 0 then

        else
            local player = {}
            player.account_id = account_id
            player.town_name = town_name
            player.level = level
            player.avatar_index = avatar_index
            exp = exp + 1
            local weight = level + (1 - 1.0/exp) * 2
            local data = cjson.encode(player)
            connect:hset("player",account_id,data)
            connect:zadd("friends", weight, account_id)
        end
    end
end

function CMD.update_player(account_id,town_name,level,exp,avatar_index)
    local player = {}
    player.account_id = account_id
    player.town_name = town_name
    player.level = level
    player.avatar_index = avatar_index
    exp = exp + 1
    local weight = level + (1 - 1.0/exp) * 2
    local data = cjson.encode(player)
    connect:hset("player",account_id,data)
    connect:zadd("friends", weight, account_id)
end

function CMD.update_friends(friends)
    local friend_objects = friends.friend_objects or {}
    local recommend_objects = friends.recommend_objects or {}
    local request_friends = friends.request_friends or {}
    local verify_friends = friends.verify_friends or {} 

    local update_friends = {}
    update_friends.friend_objects = {}
    update_friends.recommend_objects = {}
    update_friends.request_friends = {}
    update_friends.verify_friends = {}

    for i,v in ipairs(friend_objects) do
        local account_id = v.account_id
        local player = connect:hget("player",account_id) or "{}"
        update_friends.friend_objects[i] = cjson.decode(player)
    end

    for i,v in ipairs(recommend_objects) do
        local account_id = v.account_id
        local player = connect:hget("player",account_id) or "{}"
        update_friends.recommend_objects[i] = cjson.decode(player)
    end

    for i,v in ipairs(request_friends) do
        local account_id = v.account_id
        local player = connect:hget("player",account_id) or "{}"
        update_friends.request_friends[i] = cjson.decode(player)
    end

    for i,v in ipairs(verify_friends) do
        local account_id = v.account_id
        local player = connect:hget("player",account_id) or "{}"
        update_friends.verify_friends[i] = cjson.decode(player)
    end

    return update_friends
end

function CMD.query_player(account_id)
    local player = connect:hget("player",account_id) or "{}"
    return player
end

function CMD.recommend_friends(account_id,friends)
    local rank = connect:zrank("friends",account_id)
    local from = rank - 50
    local to = rank + 50
    if from < 0 then from = 0 end
    local ret = connect:zrange("friends",from,to)
    if #friends > 0 then
        connect:sadd("allfriends",table.unpack(ret))
        connect:srem("allfriends",account_id)
        connect:sadd("myfriends",table.unpack(friends))
        local recommends = connect:sdiff("allfriends","myfriends")
        if #recommends <= 0 then
            connect:del("allfriends")
            connect:del("myfriends")
            return "{}" 
        end
        connect:sadd("recommands",table.unpack(recommends))
        ret = connect:srandmember("recommands",5)
        connect:del("allfriends")
        connect:del("myfriends")
        connect:del("recommands")
    else
        connect:sadd("recommands",table.unpack(ret))
        connect:srem("recommands",account_id)
        ret = connect:srandmember("recommands",5)
        connect:del("recommands")
    end
    local players = {}
    for i,v in ipairs(ret) do
        local player = connect:hget("player",tonumber(v))
        table.insert(players,cjson.decode(player))
    end
    return players
end

function CMD.get_rank()
    local ranks = connect:zrange("friends",0,-1)
    local data = {}
    for i,v in ipairs(ranks) do
        local player = connect:hget("player",v)
        data[i] = cjson.decode(player)
    end
    return data
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)
	skynet.register(SERVICE_NAME)
end)