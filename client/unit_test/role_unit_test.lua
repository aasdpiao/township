local class = require("class")
local print_r = require("print_r")

local RoleUnitTest = class()

function RoleUnitTest:ctor(role_object)
    self.__role_object = role_object
    self.__socket_client = role_object:get_socket_client()
    self.__role_dispatcher = role_object:get_role_dispatcher()
    self.__time_manager = role_object:get_time_manager()
end

function RoleUnitTest:start_unit_test()
    self:register_s2c_callback()
    -- self.__socket_client:send_request("pull",{})
    -- self.__socket_client:send_request("cmd",{
    --     cmd = "add_exp",
    --     args = {"10"}
    -- })
    self.__socket_client:send_request("version_check",{
        version = 1
    })
    -- self.__socket_client:send_request("buy_item",{
    --     item_index = 1001, 
    --     item_count = 1, 
    --     cash_count = 1
    -- })
    -- self.__socket_client:send_request("sale_item",{
    --     item_index = 1001, 
    --     item_count = 1, 
    --     gold_count = 1
    -- })
    -- self.__socket_client:send_request("sign_in",{
    --     timestamp = self.__time_manager:get_current_time(),
    --     continue_times = 0
    -- })
    -- self.__socket_client:send_request("sign_in",{
    --     timestamp = self.__time_manager:get_current_time() + 24 * 60 * 60 * 1 ,
    --     continue_times = 1
    -- })
    -- self.__socket_client:send_request("sign_in",{
    --     timestamp = self.__time_manager:get_current_time() + 24 * 60 * 60 * 2,
    --     continue_times = 2
    -- })
    -- self.__socket_client:send_request("sign_in",{
    --     timestamp = self.__time_manager:get_current_time() + 24 * 60 * 60 * 3,
    --     continue_times = 3
    -- })
    -- self.__socket_client:send_request("sign_in",{
    --     timestamp = self.__time_manager:get_current_time() + 24 * 60 * 60 * 4,
    --     continue_times = 4
    -- })
    -- self.__socket_client:send_request("sign_in",{
    --     timestamp = self.__time_manager:get_current_time() + 24 * 60 * 60 * 5,
    --     continue_times = 5
    -- })
end

function RoleUnitTest:register_s2c_callback()
    -- self.__role_dispatcher:register_s2c_callback("pull",self.dispatcher_pull)
    -- self.__role_dispatcher:register_s2c_callback("cmd",self.dispatcher_cmd)
    self.__role_dispatcher:register_c2s_callback("version_check",self.dispatcher_version_check)
    -- self.__role_dispatcher:register_s2c_callback("buy_item",self.dispatcher_buy_item)
    -- self.__role_dispatcher:register_s2c_callback("sale_item",self.dispatcher_sale_item)
    -- self.__role_dispatcher:register_s2c_callback("sign_in",self.dispatcher_sign_in)
    self.__role_dispatcher:register_s2c_callback("send_mail",self.dispatcher_send_mail)
end

function RoleUnitTest.dispatcher_send_mail(role_object,args)
    return {result = 0}
end

function RoleUnitTest.dispatcher_pull(role_object,args1,args2)
    print("pull")
    print_r(args2)
end
function RoleUnitTest.dispatcher_cmd(role_object,args1,args2)
    print("cmd")
    print_r(args2)
end
function RoleUnitTest.dispatcher_version_check(role_object,args1,args2)
    print("version_check")
    print_r(args2)
end
function RoleUnitTest.dispatcher_buy_item(role_object,args1,args2)
    print("buy_item")
    print_r(args2)
end
function RoleUnitTest.dispatcher_sale_item(role_object,args1,args2)
    print("sale_item")
    print_r(args2)
end
function RoleUnitTest.dispatcher_sign_in(role_object,args1,args2)
    print("sign_in")
    print_r(args2)
end

return RoleUnitTest