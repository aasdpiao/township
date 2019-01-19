local skynet = require "skynet"
local cjson = require "cjson"
local packer = require "db.packer"

local httpserver = {}
local agent_manager
local notice

function httpserver.start(manager)
	agent_manager = manager
end

function httpserver.online(params)
	local users = agent_manager:get_online_agent_objects()
	local online_roles = {}
	for account_id,agent_object in pairs(users) do
		online_roles[""..account_id] = skynet.call(agent_object:get_agent(),"lua","statistics")
	end
    return online_roles
end

function httpserver.helicopter(params)
	local account_id = params.account_id or 0
	account_id = tonumber(account_id)
	local agent_object = agent_manager:get_agent_object(account_id)
	if not agent_object then return end
    return skynet.call(agent_object:get_agent(),"lua","helicopter")
end

function httpserver.trains(params)
	local account_id = params.account_id or 0
	account_id = tonumber(account_id)
	local agent_object = agent_manager:get_agent_object(account_id)
	if not agent_object then return end
    return skynet.call(agent_object:get_agent(),"lua","trains")
end

function httpserver.achievement(params)
	local account_id = params.account_id or 0
	account_id = tonumber(account_id)
	local agent_object = agent_manager:get_agent_object(account_id)
	if not agent_object then return end
    return skynet.call(agent_object:get_agent(),"lua","achievement")
end

function httpserver.market(params)
	local account_id = params.account_id or 0
	account_id = tonumber(account_id)
	local agent_object = agent_manager:get_agent_object(account_id)
	if not agent_object then return end
    return skynet.call(agent_object:get_agent(),"lua","market")
end

function httpserver.grid(params)
	local account_id = params.account_id or 0
	account_id = tonumber(account_id)
	local agent_object = agent_manager:get_agent_object(account_id)
	if not agent_object then return end
    return skynet.call(agent_object:get_agent(),"lua","grid")
end

function httpserver.employment(params)
	local account_id = params.account_id or 0
	account_id = tonumber(account_id)
	local agent_object = agent_manager:get_agent_object(account_id)
	if not agent_object then return end
    return skynet.call(agent_object:get_agent(),"lua","employment")
end

function httpserver.send_mail(params)
	local account_id = params.account_id or 0
	account_id = tonumber(account_id)
	local title = string.urldecode(params.title)
	local content = string.urldecode(params.content)
	local item_objects = params.item_objects or "{}"
	local data = {}
	data.title = title
	data.content = content
	data.item_objects = item_objects 
	local agent_object = agent_manager:get_agent_object(account_id)
	if agent_object then
		skynet.call(agent_object:get_agent(),"lua","send_mail",cjson.encode(data))
	end
	if account_id == 0 then
		local sql = string.format("call save_mail('%s','%s','%s')",packer.pack(title),packer.pack(content),packer.pack(item_objects))
		local ret = skynet.call("mysqld","lua","querygamedb",sql,1)
		local mail_id = ret[1][1][1]
		local users = agent_manager:get_online_agent_objects()
		for account_id,agent_object in pairs(users) do
			data.mail_id = tonumber(mail_id)
			skynet.call(agent_object:get_agent(),"lua","send_mail",cjson.encode(data))
		end
	end
	return {result = 0}
end

function httpserver.update_notice(params)
	local content = string.urldecode(params.content)
	notice = packer.pack(content)
	local sql = string.format("call update_notice('%s')",notice) 
	skynet.call("mysqld","lua","querygamedb",sql,1)
	return {result = 0}
end

function httpserver.get_notice(params)
	if not notice then
		local sql = "call load_notice()"
		local ret = skynet.call("mysqld","lua","querygamedb",sql)
		if ret[1][1] then
			notice = ret[1][1][2]
		end
	end
	return {notice = notice}
end

function httpserver.dump_all()
	skynet.call("redisd","lua","dump_all")
	return {result = 0}
end

function httpserver.turnoff()
	local login_master = skynet.localname(".login_master")
	skynet.call(login_master,"lua","forbid_login")
	skynet.call("gamed","lua","turnoff")
	skynet.call("redisd","lua","dump_all")
	return {result = 0}
end

function httpserver.turnon()
	local login_master = skynet.localname(".login_master")
	skynet.call(login_master,"lua","allow_login")
	return {result = 0}
end

function httpserver.queue()
	local ranks = skynet.call("recommend","lua","get_rank")
	return ranks
end

function httpserver.power_cmd(params)
	local cmd = params.cmd
	local args = params.args
	local account_id = params.account_id or 0
	account_id = tonumber(account_id)
	local agent_object = agent_manager:get_agent_object(account_id)
	if not agent_object then 
		skynet.call("gamed","lua","query_address",account_id)
		agent_object = agent_manager:get_agent_object(account_id)
	end
    return skynet.call(agent_object:get_agent(),"lua","power_cmd",cmd,args)
end

return httpserver