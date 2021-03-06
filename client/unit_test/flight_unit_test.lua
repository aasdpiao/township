local class = require("class")

local FlightUnitTest = class()

function FlightUnitTest:ctor(role_object)
    self.__role_object = role_object
    self.__socket_client = role_object:get_socket_client()
    self.__role_dispatcher = role_object:get_role_dispatcher()
end

function FlightUnitTest:start_unit_test()
    self:register_s2c_callback()
    self.__socket_client:send_request("synctime",{})
end

function FlightUnitTest:register_s2c_callback()
    self.__role_dispatcher:register_s2c_callback("synctime",self.dispatcher_synctime)
end

function FlightUnitTest.dispatcher_synctime(role_object,args1,args2)
    local time_stamp = args2.timestamp
    role_object:get_time_manager():sync_time(time_stamp)
    print("timestamp",time_stamp)
end

return FlightUnitTest