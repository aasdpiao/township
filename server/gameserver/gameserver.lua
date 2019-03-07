local skynet = require "skynet"
local gateserver = require "gameserver.gateserver"
local netpack = require "skynet.netpack"
local crypt = require "skynet.crypt"
local socketdriver = require "skynet.socketdriver"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode
local syslog = require "syslog"
local sprotoloader = require "sprotoloader"

local server = {}

local user_online = {}
local handshake = {}
local connection = {}

local host = sprotoloader.load(MSG.s2c):host "package"
local request = host:attach (sprotoloader.load (MSG.c2s))

local function send_request(username,msg)
	local u = user_online[username]
	if u then
		local package = string.pack(">s2", msg)
		socketdriver.send(u.fd, package)
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

function server.userid(username)
	-- base64(account_id)@base64(server)
	local account_id, servername = username:match "([^@]*)@(.*)"
	return b64decode(account_id), b64decode(servername)
end

function server.username(account_id, servername)
	return string.format("%s@%s", b64encode(account_id), b64encode(servername))
end

function server.logout(username)
	syslog.debugf("username :%s is logout",username)
	local u = user_online[username]
	user_online[username] = nil
	if u and u.fd then
		gateserver.closeclient(u.fd)
		connection[u.fd] = nil
	end
end

function server.login(username, secret)
	syslog.debug("login:"..username)
	assert(user_online[username] == nil)
	user_online[username] = {
		secret = secret,
		version = 0,
		index = 0,
		username = username,
		response = {},	-- response cache
	}
end

function server.ip(username)
	local u = user_online[username]
	if u and u.fd then
		return u.ip
	end
end

function server.start(conf)
	local expired_number = conf.expired_number or 128

	local handler = {}

	local CMD = {
		login = assert(conf.login_handler),
		logout = assert(conf.logout_handler),
		kick = assert(conf.kick_handler),
		request = send_request,
		http = assert(conf.request_http),
		query_address = assert(conf.query_address),
		turnoff = assert(conf.turnoff),
	}

	function handler.command(cmd, source, ...)
		local f = assert(CMD[cmd])
		return f(...)
	end

	function handler.open(source, gateconf)
		local servername = assert(gateconf.servername)
		return conf.register_handler(servername)
	end

	function handler.connect(fd, addr)
		handshake[fd] = addr
		gateserver.openclient(fd)
	end

	function handler.disconnect(fd)
		handshake[fd] = nil
		local c = connection[fd]
		if c then
			c.fd = nil
			connection[fd] = nil
			if conf.disconnect_handler then
				conf.disconnect_handler(c.username)
			end
		end
	end

	handler.error = handler.disconnect

	-- atomic , no yield
	local function do_auth(fd, message, addr)
		local username, index, hmac = string.match(message, "([^:]*):([^:]*):([^:]*)")
		local u = user_online[username]
		if u == nil then
			return "404 User Not Found"
		end
		local idx = assert(tonumber(index))
		hmac = b64decode(hmac)

		if idx <= u.version then
			return "403 Index Expired"
		end

		local text = string.format("%s:%s", username, index)
		local v = crypt.hmac_hash(u.secret, text)	-- equivalent to crypt.hmac64(crypt.hashkey(text), u.secret)
		if v ~= hmac then
			return "401 Unauthorized"
		end

		u.version = idx
		u.fd = fd
		u.ip = addr
		connection[fd] = u
	end

	local function auth(fd, addr, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, result = pcall(do_auth, fd, message, addr)
		if not ok then
			skynet.error(result)
			result = "400 Bad Request"
		end

		local close = result ~= nil

		if result == nil then
			result = "200 OK"
		end
		socketdriver.send(fd, netpack.pack(result))

		if close then
			gateserver.closeclient(fd)
		end
	end

	local request_handler = assert(conf.request_handler)

	local function do_request(fd, msg, sz)
		local u = assert(connection[fd], "invalid fd")
		local ok, result = pcall(conf.request_handler, u.username, msg, sz)
		if not ok then
			syslog.debug("do_request error")
		elseif not result then
			syslog.debug("do_request not result")
		elseif #result == 0 then
			syslog.debug("do_request result = 0")
		else
			socketdriver.send(fd, netpack.pack(result))
		end
	end

	local function request(fd, msg, sz)
		local ok, err = pcall(do_request, fd, msg, sz)
		-- not atomic, may yield
		if not ok then
			skynet.error(string.format("Invalid package %s", err))
			if connection[fd] then
				gateserver.closeclient(fd)
			end
		end
	end

	function handler.message(fd, msg, sz)
		local addr = handshake[fd]
		if addr then
			auth(fd,addr,msg,sz)
			handshake[fd] = nil
		else
			request(fd, msg, sz)
		end
	end

	return gateserver.start(handler)
end

return server
