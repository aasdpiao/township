local login = require "loginserver.loginserver"
local crypt = require "skynet.crypt"
local skynet = require "skynet"
local print_r = require "print_r"
local syslog = require "syslog"

local server_list = {}
local user_online = {}
local user_login = {}
local forbid_login = false
local CMD = {}


local function register_handler(account, server, password)
	syslog.debugf("%s@%s is login, password is %s", account, server, password)
	account = crypt.base64decode(account)
	password = crypt.base64decode(password)
	server = crypt.base64decode(server)
	local mysqld = skynet.queryservice("mysqld")
	local sql = string.format("call register_new_account('%s', '%s', '%s')",account,password,server)
	local ret = skynet.call(mysqld,"lua","queryaccountdb",sql,true)
	local retcode = ret[1][1][1]
	local account_id = ret[1][1][2]
	if retcode == 100 then
		sql = string.format("call new_player(%d,%s)",account_id,""..account_id)
		skynet.call(mysqld,"lua","querygamedb",sql,true)
	end
	return retcode,tonumber(account_id)
end

local function auth_handler(user, server, password)
	user = crypt.base64decode(user)
	server = crypt.base64decode(server)
	password = crypt.base64decode(password)
	local mysqld = skynet.queryservice("mysqld")
	local sql = string.format("call check_account_and_password('%s', '%s')",user,password)
	local ret = skynet.call(mysqld,"lua","queryaccountdb",sql)
	local retcode = ret[1][1][1]
	local account_id= ret[1][1][2]
	return retcode,tonumber(account_id)
end

local function login_handler(server, account_id, secret)
	syslog.debugf("%s@%s is login, secret is %s", account_id, server, crypt.hexencode(secret))
	local gameserver = assert(server_list[server], "Unknown server")
	-- only one can login, because disallow multilogin
	local last = user_online[account_id]
	if last then
		skynet.call(last.address, "lua", "kick", account_id)
	end
	if user_online[account_id] then
		error(string.format("user %s is already online", account_id))
	end
	if forbid_login then
		error(string.format("user %s forbid login", account_id))
		return
	end
	skynet.call(gameserver, "lua", "login", account_id, secret)
	user_online[account_id] = { address = gameserver, account_id = account_id , server = server}
end

local function command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

function CMD.register_gate(server, address)
	syslog.debugf("server:%s,address:%s",server,address)
	server_list[server] = address
end

function CMD.logout(account_id)
	local u = user_online[account_id]
	if u then
		syslog.debugf("%s@%s is logout", account_id, u.server)
		user_online[account_id] = nil
	end
end

function CMD.forbid_login()
	forbid_login = true
end

function CMD.allow_login()
	forbid_login = false
end

local server_conf = {
	host = "0.0.0.0",
	port = tonumber(skynet.getenv "login_port"),
	multilogin = false,	-- disallow multilogin
	name = "login_master",
	register_handler = register_handler,
	auth_handler = auth_handler,
	login_handler = login_handler,
	command_handler = command_handler,
}

login(server_conf)
