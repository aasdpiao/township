local class = require("class")

local AchievementUnitTest = class()

function AchievementUnitTest:ctor(role_object)
    self.__role_object = role_object
    self.__socket_client = role_object:get_socket_client()
    self.__role_dispatcher = role_object:get_role_dispatcher()
end

function AchievementUnitTest:start_unit_test()
    self:register_s2c_callback()
    self.__socket_client:send_request("pull",{})
    self.__socket_client:send_request("cmd",{})
    self.__socket_client:send_request("version_check",{})
    self.__socket_client:send_request("buy_item",{})
    self.__socket_client:send_request("sale_item",{})
    self.__socket_client:send_request("sign_in",{})
end

function AchievementUnitTest:register_s2c_callback()
    self.__role_dispatcher:register_s2c_callback("pull",self.dispatcher_pull)
    self.__role_dispatcher:register_s2c_callback("cmd",self.dispatcher_cmd)
    self.__role_dispatcher:register_s2c_callback("version_check",self.dispatcher_version_check)
    self.__role_dispatcher:register_s2c_callback("buy_item",self.dispatcher_buy_item)
    self.__role_dispatcher:register_s2c_callback("sale_item",self.dispatcher_sale_item)
    self.__role_dispatcher:register_s2c_callback("sign_in",self.dispatcher_sign_in)
end

function AchievementUnitTest.dispatcher_pull(role_object,args1,args2)
    print("timestamp")
end
function AchievementUnitTest.dispatcher_cmd(role_object,args1,args2)
    print("timestamp")
end
function AchievementUnitTest.dispatcher_version_check(role_object,args1,args2)
    print("timestamp")
end
function AchievementUnitTest.dispatcher_buy_item(role_object,args1,args2)
    print("timestamp")
end
function AchievementUnitTest.dispatcher_sale_item(role_object,args1,args2)
    print("timestamp")
end
function AchievementUnitTest.dispatcher_sign_in(role_object,args1,args2)
    print("timestamp")
end

return AchievementUnitTest