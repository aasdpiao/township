local class = require("class")

local MarketUnitTest = class()

function MarketUnitTest:ctor(role_object)
    self.__role_object = role_object
    self.__socket_client = role_object:get_socket_client()
    self.__role_dispatcher = role_object:get_role_dispatcher()
    self.__time_manager = role_object:get_time_manager()
end

function MarketUnitTest:start_unit_test()
    self:register_s2c_callback()
    self.__socket_client:send_request("request_market",{
        timestamp = self.__time_manager:get_current_time(),
    })
end

function MarketUnitTest:register_s2c_callback()
    self.__role_dispatcher:register_s2c_callback("unlock_market",self.dispatcher_unlock_market)
end

function MarketUnitTest.dispatcher_unlock_market(role_object,args1,args2)
    
end

return MarketUnitTest