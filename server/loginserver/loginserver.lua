local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local crypt = require "skynet.crypt"
local syslog = require "syslog"
local table = table
local string = string
local assert = assert

local socket_error = {}

local function assert_socket(service, v, fd)
	if v then
		return v
	else
		skynet.error(string.format("%s failed: socket (fd = %d) closed", service, fd))
		error(socket_error)
	end
end

local function write(service, fd, text)
	local package = string.pack (">s2", text)
	assert_socket(service, socket.write(fd, package), fd)
end

local function read (fd, size)
	return socket.read (fd, size) or error ()
end

local function read_msg (fd)
	local s = read (fd, 2)
	local size = s:byte(1) * 256 + s:byte(2)
	local package = read (fd, size)
	return package
end


local function launch_slave(auth_handler,register_handler)
	local function auth(fd, addr)
		socket.limit(fd, 8192)
		local challenge = crypt.randomkey()
		write("auth", fd, crypt.base64encode(challenge))
		local handshake = assert_socket("auth", read_msg(fd), fd)
		local clientkey = crypt.base64decode(handshake)
		if #clientkey ~= 8 then
			error "Invalid client key"
		end
		local serverkey = crypt.randomkey()
		write("auth", fd, crypt.base64encode(crypt.dhexchange(serverkey)))
		local secret = crypt.dhsecret(clientkey, serverkey)
		local response = assert_socket("auth", read_msg(fd), fd)
		local hmac = crypt.hmac64(challenge, secret)
		if hmac ~= crypt.base64decode(response) then
			write("auth", fd, "400 Bad Request")
			error "challenge failed"
		end
		local etoken = assert_socket("auth", read_msg(fd),fd)
		local token = crypt.desdecode(secret, crypt.base64decode(etoken))
		local user, server, password, request_type = token:match("([^@]+)@([^#]+)#([^:]+):(.+)")
		request_type = crypt.base64decode(request_type)
		local ok, retcode, account_id
		if string.lower (request_type) == "register" then
			ok, retcode,account_id =  pcall(register_handler, user, server, password)
		else
			ok, retcode,account_id =  pcall(auth_handler, user, server, password)
		end
		server = crypt.base64decode(server)
		return ok, retcode, server, account_id, secret
	end

	local function ret_pack(ok, err, ...)
		if ok then
			return skynet.pack(err, ...)
		else
			if err == socket_error then
				return skynet.pack(nil, "socket error")
			else
				return skynet.pack(false, err)
			end
		end
	end

	local function auth_fd(fd, addr)
		skynet.error(string.format("connect from %s (fd = %d)", addr, fd))
		socket.start(fd)	-- may raise error here
		local msg, len = ret_pack(pcall(auth, fd, addr))
		socket.abandon(fd)	-- never raise error here
		return msg, len
	end

	skynet.dispatch("lua", function(_,_,...)
		local ok, msg, len = pcall(auth_fd, ...)
		if ok then
			skynet.ret(msg,len)
		else
			skynet.ret(skynet.pack(false, msg))
		end
	end)
end

local user_login = {}

local function accept(conf, slave, fd, addr)
	-- call slave auth
	local ok, retcode, server, account_id, secret = skynet.call(slave, "lua",  fd, addr)
	-- slave will accept(start) fd, so we can write to fd later
	
	if not ok then
		write("response 401", fd, "401 Unauthorized")
		return
	end
	if tonumber(retcode) == 101 then
		write("response 101", fd, "101 register faild")
		return 
	elseif tonumber(retcode) == 100 then
		write("response 101", fd, "100 register success")
		return 
	elseif tonumber(retcode) == 201 then
		write("response 201", fd, "201 login faild")
		return 
	end

	if not conf.multilogin then
		if user_login[account_id] then
			write("response 406", fd, "406 Not Acceptable")
			--error(string.format("User %s is already login", account_id))
		end
		user_login[account_id] = true
	end

	ok = pcall(conf.login_handler, server, account_id, secret)
	user_login[account_id] = nil

	if ok then
		account_id = account_id or ""
		write("response 200",fd,  "200 "..crypt.base64encode(tostring(account_id)))
	else
		write("response 403",fd,  "403 Forbidden")
	end
end

local function launch_master(conf)
	local instance = conf.instance or 8
	assert(instance > 0)
	local host = conf.host or "0.0.0.0"
	local port = assert(tonumber(conf.port))
	local slave = {}
	local balance = 1

	skynet.dispatch("lua", function(_,source,command, ...)
		skynet.ret(skynet.pack(conf.command_handler(command, ...)))
	end)

	for i=1,instance do
		table.insert(slave, skynet.newservice(SERVICE_NAME))
	end

	skynet.error(string.format("login server listen at : %s %d", host, port))
	local id = socket.listen(host, port)
	socket.start(id , function(fd, addr)
		local s = slave[balance]
		balance = balance + 1
		if balance > #slave then
			balance = 1
		end
		local ok, err = pcall(accept, conf, s, fd, addr)
		if not ok then
			if err ~= socket_error then
				skynet.error(string.format("invalid client (fd = %d) error = %s", fd, err))
			end
		end
		socket.close_fd(fd)	-- We haven't call socket.start, so use socket.close_fd rather than socket.close.
	end)
end

local function login(conf)
	local name = "." .. (conf.name or "login")
	skynet.start(function()
		local loginmaster = skynet.localname(name)
		if loginmaster then
			local auth_handler = assert(conf.auth_handler)
			local register_handler = assert(conf.register_handler)
			launch_master = nil
			conf = nil
			launch_slave(auth_handler,register_handler)
		else
			launch_slave = nil
			conf.auth_handler = nil
			conf.register_handler = nil
			assert(conf.login_handler)
			assert(conf.command_handler)
			skynet.register(name)
			launch_master(conf)
		end
	end)
end

return login
