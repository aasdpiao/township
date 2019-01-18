local class = require("class")
local print_r = require("print_r")
local socket = require("client.socket")
local crypt = require("client.crypt")
local sprotoparser = require("sprotoparser")
local sproto = require("sproto")
local base64encode = crypt.base64encode
local base64decode = crypt.base64decode

local traceback = debug.traceback

local c2s_sproto_file = {
	"1_role",
	"2_plant",
	"3_grid",
	"4_time",
	"5_factory",
	"6_breed",
	"7_trains",
	"8_seaport",
	"9_flight",
	"10_helicopter",
	"11_achievement",
	"12_market",
	"13_employment",
}

local s2c_sproto_file = {
	"1_role"
}

local SocketClient = class()

function SocketClient:ctor(role_object,conf,token)
    self.__role_object = role_object
    self.__login_address = conf.login_address
    self.__login_port = conf.login_port
    self.__game_address = conf.game_address
    self.__game_port = conf.game_port

    self.__token = token
    self.__fd = 0
    self.__secret = ""

    self.__session = {}
    self.__session_id = 0

    self.__host = nil
    self.__request = nil
end

function SocketClient:init()
    local c2s_proto = self:load_c2s_sproto()
    local s2c_proto = self:load_s2c_sproto()
    self.__host = sproto.new (s2c_proto):host "package"
    self.__request = self.__host:attach (sproto.new (c2s_proto))
end

function SocketClient:read(name)
	local filename = string.format("proto/%s.sproto", name)
	local f = assert(io.open(filename), "Can't open " .. filename)
	local t = f:read "a"
	f:close()
	return t
end

function SocketClient:load_c2s_sproto()
	local attr = self:read("proto.attr")
	local sp = "\n"
	for i,file_name in ipairs(c2s_sproto_file) do
		local name = "c2s/"..file_name
		sp = sp .. self:read(name).."\n"
	end
	return sprotoparser.parse(attr..sp)
end

function SocketClient:load_s2c_sproto()
	local attr = self:read("proto.attr")
	local sp = "\n"
	for i,file_name in ipairs(s2c_sproto_file) do
		local name = "s2c/"..file_name
		sp = sp .. self:read(name).."\n"
	end
	return sprotoparser.parse(attr..sp)
end

function SocketClient:send_message (msg)
	local package = string.pack (">s2", msg)
	socket.send (self.__fd, package)
end

function SocketClient:unpack (text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte (1) * 256 + text:byte (2)
	if size < s + 2 then
		return nil, text
	end
	return text:sub (3, 2 + s), text:sub (3 + s)
end

function SocketClient:recv_message (last)
	local function try_recv(last)
		local result
		result, last = self:unpack(last)
		if result then
			return result, last
		end
		local r = socket.recv(self.__fd)
		if not r then
			return nil, last
		end
		if r == "" then
			error("Server closed")
		end
		return self:unpack(last .. r)
	end

	return function()
		while true do
			local result
			result, last = try_recv(last)
			if result then
				print(result,last)
				return result
			end
			socket.usleep(100)
		end
	end
end

function SocketClient:encode_token()
	return string.format("%s@%s#%s:%s",
		crypt.base64encode(self.__token.user),
		crypt.base64encode(self.__token.server),
		crypt.base64encode(self.__token.pass),
		crypt.base64encode(self.__token.request_type)
	)
end

function SocketClient:Register()
	local last = ""
    self.__fd = socket.connect(self.__login_address, self.__login_port)
    local challenge = crypt.base64decode(self:recv_message(last)())

    local clientkey = crypt.randomkey()
    self:send_message(crypt.base64encode(crypt.dhexchange(clientkey)))

    local secret = crypt.dhsecret(crypt.base64decode(self:recv_message(last)()), clientkey)

    self.__secret = secret

    print("sceret is ", crypt.hexencode(secret))

    local hmac = crypt.hmac64(challenge, secret)
	self:send_message(crypt.base64encode(hmac))
	
    local etoken = crypt.desencode(secret, self:encode_token())
	self:send_message(crypt.base64encode(etoken))

	local result = self:recv_message(last)()

	print(result)
	socket.close(self.__fd)
	self.__fd = 0
end

function SocketClient:Login()
    local last = ""
    self.__fd = socket.connect(self.__login_address, self.__login_port)
    local challenge = crypt.base64decode(self:recv_message(last)())

    local clientkey = crypt.randomkey()
    self:send_message(crypt.base64encode(crypt.dhexchange(clientkey)))

    local secret = crypt.dhsecret(crypt.base64decode(self:recv_message(last)()), clientkey)

    self.__secret = secret

    print("sceret is ", crypt.hexencode(secret))

    local hmac = crypt.hmac64(challenge, secret)
    self:send_message(crypt.base64encode(hmac))

    self.__token.request_type = "login"

    etoken = crypt.desencode(secret, self:encode_token())
    self:send_message(crypt.base64encode(etoken))

    local result = self:recv_message(last)()
	print(result)
    local code = tonumber(string.sub(result, 1, 3))
    assert(code == 200)
    socket.close(self.__fd)
    self.__fd = 0
    local account_id = crypt.base64decode(string.sub(result, 5))
    return tonumber(account_id)
end

function SocketClient:ConnectGameServer(account_id)
    local last = ""
    self.__fd = assert(socket.connect(self.__game_address, self.__game_port))
    -- base64(account_id)@base64(server)
    local handshake = string.format("%s@%s:%d", crypt.base64encode(account_id), crypt.base64encode(self.__token.server), 1)
    local hmac = crypt.hmac64(crypt.hashkey(handshake), self.__secret)
    self:send_message(handshake .. ":" .. crypt.base64encode(hmac))
    print(self:recv_message(last)())
end

function SocketClient:send_request (name, args)
	print("send_request :"..name)
    self.__session_id = self.__session_id + 1
    local str = self.__request(name, args,self.__session_id)
    self:send_message ( str)
    self.__session[self.__session_id] = { name = name, args = args }
end

function SocketClient:dispatch_message()
    local last = ""
	local msg = self:recv_message(last)()
	print("msg:",base64encode(msg))
	self:handle_message (self.__host:dispatch (msg))
end

function SocketClient:handle_message (t, ...)
	print("t:",t)
	if t == "REQUEST" then
		self:handle_request (...)
	else
		self:handle_response (...)
	end
end

function SocketClient:handle_request (name, args, response)
	local f = self.__role_object:get_handle_request(name)
	local ok, ret = xpcall (f, traceback,self.__role_object,args)
	if ok then
		local msg = response(ret)
		self:send_message(msg)
	end
end

function SocketClient:handle_response (id, args)
	local s = assert (self.__session[id])
	self.__session[id] = nil
	local f = self.__role_object:get_handle_response(s.name)
	if f then
		xpcall(f,traceback,self.__role_object,s.args, args)
	else
		print_r (args)
	end
end

return SocketClient