local gameserver = require "gameserver.gameserver"
local crypt = require "skynet.crypt"
local skynet = require "skynet"
local syslog = require "syslog"
local AgentManager = require "agent_manager"
local cjson = require "cjson"
local httpserver = require "httpserver.httpserver"
local md5 = require "md5"

local loginservice = tonumber(...)
local servername 

local md5_key = "h!2@jhDASD54**-_FD"

local server = {}
local agent_manager = AgentManager.new()

function server.login_handler(account_id, secret)
	local agent_object = agent_manager:get_agent_object(account_id)
	local username = gameserver.username(account_id,servername)
	if agent_object then
		LOG_INFO("%d:%s",account_id,"login")
	else
		agent_object = agent_manager:new_role_agnet(account_id,username)
	end
	agent_object:set_offline(false)
	skynet.call(agent_object:get_agent(), "lua", "login",skynet.self(), account_id, username)
	gameserver.login(username, secret)
end

-- call by agent
function server.logout_handler(account_id)
	local agent_object = agent_manager:get_agent_object(account_id)
	if agent_object then
		local username = gameserver.username(account_id, servername)
		assert(agent_object:get_username() == username)
		gameserver.logout(agent_object:get_username())
		skynet.call(loginservice, "lua", "logout", account_id)
		agent_manager:role_agent_logout(agent_object)
	end
end

-- call by login server
function server.kick_handler(account_id)
	local agent_object = agent_manager:get_agent_object(account_id)
	if agent_object then
		local username = gameserver.username(account_id, servername)
		assert(agent_object:get_username() == username)
		--NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, agent_object:get_agent(), "lua", "logout")
	end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username)
	local agent_object = agent_manager:get_agent_object_by_username(username)
	if agent_object then
		skynet.call(agent_object:get_agent(), "lua", "disconnect")
	end
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg, sz)
	local agent_object = agent_manager:get_agent_object_by_username(username)
	if agent_object then
		return skynet.tostring(skynet.rawcall(agent_object:get_agent(), "client", msg, sz))
	end
end

-- call by self (when gate open)
function server.register_handler(name)
	servername = name
	skynet.call(loginservice, "lua", "register_gate", servername, skynet.self())
end

function server.query_address(account_id)
	local agent_object = agent_manager:get_agent_object(account_id)
	local username = gameserver.username(account_id,servername)
	if not agent_object then
		agent_object = agent_manager:new_role_agnet(account_id,username)
		agent_object:set_offline(true)
		skynet.call(agent_object:get_agent(), "lua", "offline_load",skynet.self(), account_id, username)
	end
	return agent_object:get_agent()
end

function server.request_http(args)
	local params = cjson.decode(args)
	local request = params.request
	local random = params.random
	local key = params.key
	if not random or not key then return end
	local sign = md5.sumhexa(random..md5_key)
	if key ~= sign then return skynet.packstring("sign error") end
	local f = httpserver[request]
	if not f then return skynet.packstring("request is nil") end
	local result = f(params)
	return skynet.packstring(cjson.encode(result))
end

function server.turnoff()
	local agent_objects = agent_manager:get_online_agent_objects()
	for account_id,agent_object in pairs(agent_objects) do
		skynet.call(agent_object:get_agent(), "lua", "disconnect")
	end
	agent_objects = agent_manager:get_offline_agent_objects()
	for account_id,agent_object in pairs(agent_objects) do
		skynet.call(agent_object:get_agent(), "lua", "save_player")
	end
end

gameserver.start(server)
httpserver.start(agent_manager)

