local class = require("class")
local print_r = require("print_r")

local SeaportUnitTest = class()

function SeaportUnitTest:ctor(role_object)
    self.__role_object = role_object
    self.__socket_client = role_object:get_socket_client()
    self.__role_dispatcher = role_object:get_role_dispatcher()
    self.__time_manager = role_object:get_time_manager()
end

function SeaportUnitTest:start_unit_test()
    -- self.__socket_client:send_request("cmd",{
    --     cmd = "set_level",
    --     args = {"30"}
    -- })

    -- self.__socket_client:send_request("cmd",{
    --     cmd = "add_item",
    --     args = {"5001 13"}
    -- })
    -- self.__socket_client:send_request("cmd",{
    --     cmd = "add_item",
    --     args = {"5002 11"}
    -- })
    -- self.__socket_client:send_request("cmd",{
    --     cmd = "add_item",
    --     args = {"5003 9"}
    -- })
    -- self.__socket_client:send_request("cmd",{
    --     cmd = "add_cash",
    --     args = {"10000"}
    -- })
    -- self.__socket_client:send_request("cmd",{
    --     cmd = "add_gold",
    --     args = {"10000"}
    -- })
    self:register_s2c_callback()
    -- self.__socket_client:send_request("unlock_seaport",{
    --     timestamp = self.__time_manager:get_current_time(),
    --     gold_count = 8000
    -- })
    -- self.__socket_client:send_request("promote_seaport",{
    --     timestamp = self.__time_manager:get_current_time(),
    --     cash_count = 20
    -- })
    -- self.__socket_client:send_request("finish_seaport",{
    --     timestamp = self.__time_manager:get_current_time(),
    --     item_objects = {
    --         {item_index = 5001,item_count = 13 },
    --         {item_index = 5002,item_count = 11 },
    --         {item_index = 5003,item_count = 9 }
    --     }
    -- })
    self.__socket_client:send_request("set_sail",{
        timestamp = self.__time_manager:get_current_time(),
        ship_index = 5008001,
        gold_count = 70,
        island_index = 1001,
        commodity_objects = {
            {item_index = 1001,item_count = 1}
        }
    })
    self.__socket_client:send_request("promote_set_sail",{
        timestamp = self.__time_manager:get_current_time(),
        ship_index = 5008001,
        cash_count = 10
    })
    self.__socket_client:send_request("harvest_ship",{
        timestamp = self.__time_manager:get_current_time(),
        ship_index = 5008001,
        reward_objects = {
            {reward_index = 1},
            {reward_index = 2},
            {reward_index = 3},
            {reward_index = 4}
        }
    })
    self.__socket_client:send_request("refresh_harbor",{
        timestamp = self.__time_manager:get_current_time(),
        island_index = 1002
    })
    self.__socket_client:send_request("promote_harbor",{
        timestamp = self.__time_manager:get_current_time(),
        island_index = 1002,
        cash_count = 1
    })
end

function SeaportUnitTest:register_s2c_callback()
    self.__role_dispatcher:register_s2c_callback("unlock_seaport",self.dispatcher_unlock_seaport)
    self.__role_dispatcher:register_s2c_callback("promote_seaport",self.dispatcher_promote_seaport)
    self.__role_dispatcher:register_s2c_callback("finish_seaport",self.dispatcher_finish_seaport)
    self.__role_dispatcher:register_s2c_callback("set_sail",self.dispatcher_set_sail)
    self.__role_dispatcher:register_s2c_callback("promote_set_sail",self.dispatcher_promote_set_sail)
    self.__role_dispatcher:register_s2c_callback("harvest_ship",self.dispatcher_harvest_ship)
    self.__role_dispatcher:register_s2c_callback("refresh_harbor",self.dispatcher_refresh_harbor)
    self.__role_dispatcher:register_s2c_callback("promote_harbor",self.dispatcher_promote_harbor)
end

function SeaportUnitTest.dispatcher_unlock_seaport(role_object,args1,args2)
    print("unlock_seaport")
    print_r(args2)
end

function SeaportUnitTest.dispatcher_promote_seaport(role_object,args1,args2)
    print("promote_seaport")
    print_r(args2)
end

function SeaportUnitTest.dispatcher_finish_seaport(role_object,args1,args2)
    print("finish_seaport")
    print_r(args2)
end

function SeaportUnitTest.dispatcher_set_sail(role_object,args1,args2)
    print("set_sail")
    print_r(args2)
end

function SeaportUnitTest.dispatcher_promote_set_sail(role_object,args1,args2)
    print("promote_set_sail")
    print_r(args2)
end

function SeaportUnitTest.dispatcher_harvest_ship(role_object,args1,args2)
    print("harvest_ship")
    print_r(args2)
end

function SeaportUnitTest.dispatcher_refresh_harbor(role_object,args1,args2)
    print("refresh_harbor")
    print_r(args2)
end

function SeaportUnitTest.dispatcher_promote_harbor(role_object,args1,args2)
    print("promote_harbor")
    print_r(args2)
end

return SeaportUnitTest