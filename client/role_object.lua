local class = require("class")

local SocketClient = require("client.socket_client")
local RoleDispatcher = require("client.role_dispatcher")
local socket = require("client.socket")
local TimeManger = require("client.time_manager")

local RoleUnitTest = require("client.unit_test.role_unit_test")
local SeaportUnitTest = require("client.unit_test.seaport_unit_test")
local MarketUnitTest = require("client.unit_test.market_unit_test")

local RoleObject = class()

local conf = {
    login_address = "127.0.0.1",
    login_port = 6001,
    game_address = "127.0.0.1",
    game_port = 6666
}

function RoleObject:ctor(token)
    self.__token = token
    self.__account_id = 0
    self.__socket_client = SocketClient.new(self,conf,token)
    self.__socket_client:init()
    self.__role_dispatcher = RoleDispatcher.new()
    self.__role_dispatcher:init()
    self.__time_manager = TimeManger.new()
    self.__time_manager:init()
end

function RoleObject:get_socket_client()
    return self.__socket_client
end

function RoleObject:get_role_dispatcher()
    return self.__role_dispatcher
end

function RoleObject:get_time_manager()
    return self.__time_manager
end

function RoleObject:start()
    self.__account_id = self.__socket_client:Register(self.__token)
    self.__account_id = self.__socket_client:Login(self.__token)
    self.__socket_client:ConnectGameServer(self.__account_id)


    -- local role_unit_test = RoleUnitTest.new(self)
    -- role_unit_test:start_unit_test()
    
    self.message_route(self)
end

function RoleObject:get_time_manager()
    return self.__time_manager
end

function RoleObject:message_route()
    while true do
        self.__socket_client:dispatch_message()
        socket.usleep(100)
    end
end

function RoleObject:get_handle_response(name)
    return self.__role_dispatcher:get_handle_response(name)
end

function RoleObject:get_handle_request(name)
    return self.__role_dispatcher:get_handle_request(name)
end

return RoleObject