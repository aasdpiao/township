local skynet = require "skynet"
local queue = require "skynet.queue"
local syslog = require "syslog"
local RoleObject = require "role.role_object"
local sprotoloader = require "sprotoloader"
local print_r = require "print_r"
local cjson = require "cjson"
local Timer = require "timer"
local admin_power = require "role.admin_power"

local gate
local user
local traceback = debug.traceback

local host = sprotoloader.load(MSG.c2s):host "package"
local request = host:attach (sprotoloader.load (MSG.s2c))

local CMD = {}

session_id = 0
session = {}
local timer_id 

local save_timer = Timer.new()
save_timer:init()

-- 处理客户端来的请求消息
-- 这里的local REQUEST在后面的几个register里merge了很多方法进来
local function handle_request (name, args, response)
	user:set_dirty(true)
	user:add_user_record("handle_request:%s args:\n%s",name,table.tostring(args))
	local f = user:get_handle_request(name)
	if f then
		local ok, ret = xpcall (f, traceback, user, args)
		if not ok then
			syslog.warningf ("handle message(%s) failed : %s", name, ret) 
		else
			if response and ret then
				if name == "pull" or name == "access_manor" then
					local data = copy(ret)
					data.grid_data = {}
					user:add_user_record("response:%s args:\n%s",name,table.tostring(data))
				else
					user:add_user_record("response:%s args:\n%s",name,table.tostring(ret))
				end
				return response (ret)
			end
		end
	else
		syslog.warningf ("unhandled message : %s", name)
	end
end

local function string_split(str, delimiter)
	if str==nil or str=='' or delimiter==nil then
		return nil
	end
	
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function send_request (name, args)
	user:set_dirty(true)
	user:add_user_record("send_request:%s args:\n%s",name,table.tostring(args))
	session_id = session_id + 1
	local msg = request (name, args, session_id)
	skynet.send(gate,"lua", "request",user:get_username(),msg)
	session[session_id] = { name = name, args = args }
end

local function handle_response(id, args)
	local s = session[id]
	session[id] = nil
	if not s then
		syslog.warningf ("session %d not found", id)
		return
	end
	user:add_user_record("handle_response:%s args:\n%s",s.name,table.tostring(args))
	local f = user:get_handle_response(s.name)
	if not f then
		syslog.warningf ("unhandled response : %s", s.name)
		return
	end
	local ok, ret = xpcall (f, traceback, user, s.args, args)
	if not ok then
		syslog.warningf ("handle response(%d-%s) failed : %s", id, s.name, ret) 
	end
end

function CMD.login(source, account_id, username)
	if user then
		user:set_offline(0)
	else
		gate = source
		user = RoleObject.new( account_id, username, send_request)
		user:init(0)
		user:add_user_record("login")
	end
end

function CMD.offline_load(source, account_id, username)
	gate = source
	user = RoleObject.new( account_id, username, send_request)
	user:init(1)
	user:add_user_record("offline_load")
end

function CMD.statistics()
	local statistics = user:get_http_statistics()
	return cjson.encode(statistics)
end

function CMD.helicopter()
	return user:get_http_helicopter()
end

function CMD.trains()
	return user:get_http_trains()
end

function CMD.achievement()
	return user:get_http_achievement()
end

function CMD.market()
	return user:get_http_market()
end

function CMD.grid()
	return user:get_http_grid()
end

function CMD.employment()
	return user:get_http_employment()
end

function CMD.power_cmd(cmd,cmd_args)
	local func = admin_power[cmd]
    local result = 0
    if func then
    	local args = string_split(cmd_args,"_")
        result = func(user,args)
    else
        syslog.err("cmd:"..cmd.." not callback")
    end
    return result
end

function CMD.send_mail(data)
	user:send_mail(data)
end

function CMD.handle_request(...)
	user:set_dirty(true)
	return user:get_cache_ruler():handle_request(...)
end

function CMD.logout()
	user:add_user_record("logout")
	user:save_player()
	skynet.call(gate,"lua", "logout",user:get_account_id())
	user:set_offline(1)
end

function CMD.save_player()
	user:save_player()
end

function CMD.disconnect()
	user:add_user_record("disconnect")
	user:save_player()
	skynet.call(gate,"lua", "logout",user:get_account_id())
end

function CMD.active_auto_save()
	timer_id = save_timer:register(100, function()
		user:save_player()
	end,true)
end

function CMD.deactive_auto_save()
	syslog.debug("deactive_auto_save",user:get_account_id())
	save_timer:unregister(timer_id)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(...)))
	end)
end)

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch (msg, sz)
	end,
	dispatch = function (_, _, type, ...)
		if type == "REQUEST" then
			skynet.ret(handle_request(...))
		elseif type == "RESPONSE" then
			skynet.ret(handle_response(...))
		end
	end,
}

skynet.info_func(function()
		return user:debug_info()
    end)