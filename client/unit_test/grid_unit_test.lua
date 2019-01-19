local class = require("class")
local print_r = require("print_r")

local GridUnitTest = class()

function GridUnitTest:ctor(role_object)
    self.__role_object = role_object
    self.__socket_client = role_object:get_socket_client()
    self.__role_dispatcher = role_object:get_role_dispatcher()
end

function GridUnitTest:start_unit_test()
    self:register_s2c_callback()
    self.__socket_client:send_request("create_build",{})
    self.__socket_client:send_request("move_build",{})
    self.__socket_client:send_request("promote_build",{})
    self.__socket_client:send_request("finish_build",{})
    self.__socket_client:send_request("remove_road",{})
    self.__socket_client:send_request("create_road",{})
    self.__socket_client:send_request("remove_green",{})
    self.__socket_client:send_request("create_green",{})
    self.__socket_client:send_request("create_floor",{})
    self.__socket_client:send_request("remove_floor",{})
    self.__socket_client:send_request("open_undevelop",{})
    self.__socket_client:send_request("promote_undevelop",{})
    self.__socket_client:send_request("finish_undevelop",{})
    self.__socket_client:send_request("add_worker",{})
    self.__socket_client:send_request("get_off_work",{})
end

function GridUnitTest:register_s2c_callback()
    self.__role_dispatcher:register_s2c_callback("create_build",self.dispatcher_create_build)
    self.__role_dispatcher:register_s2c_callback("move_build",self.dispatcher_move_build)
    self.__role_dispatcher:register_s2c_callback("promote_build",self.dispatcher_promote_build)
    self.__role_dispatcher:register_s2c_callback("finish_build",self.dispatcher_finish_build)
    self.__role_dispatcher:register_s2c_callback("remove_road",self.dispatcher_remove_road)
    self.__role_dispatcher:register_s2c_callback("create_road",self.dispatcher_create_road)
    self.__role_dispatcher:register_s2c_callback("remove_green",self.dispatcher_remove_green)
    self.__role_dispatcher:register_s2c_callback("create_green",self.dispatcher_create_green)
    self.__role_dispatcher:register_s2c_callback("create_floor",self.dispatcher_create_floor)
    self.__role_dispatcher:register_s2c_callback("remove_floor",self.dispatcher_remove_floor)
    self.__role_dispatcher:register_s2c_callback("open_undevelop",self.dispatcher_open_undevelop)
    self.__role_dispatcher:register_s2c_callback("promote_undevelop",self.dispatcher_promote_undevelop)
    self.__role_dispatcher:register_s2c_callback("finish_undevelop",self.dispatcher_finish_undevelop)
    self.__role_dispatcher:register_s2c_callback("add_worker",self.dispatcher_add_worker)
    self.__role_dispatcher:register_s2c_callback("get_off_work",self.dispatcher_get_off_work)
end

function GridUnitTest.dispatcher_synctime(role_object,args1,args2)
    print("create_build")
    print_r(args2)
end

function GridUnitTest.dispatcher_move_build(role_object,args1,args2)
    print("move_build")
    print_r(args2)
end

function GridUnitTest.dispatcher_promote_build(role_object,args1,args2)
    print("promote_build")
    print_r(args2)
end

function GridUnitTest.dispatcher_finish_build(role_object,args1,args2)
    print("finish_build")
    print_r(args2)
end

function GridUnitTest.dispatcher_remove_road(role_object,args1,args2)
    print("remove_road")
    print_r(args2)
end

function GridUnitTest.dispatcher_create_road(role_object,args1,args2)
    print("create_road")
    print_r(args2)
end

function GridUnitTest.dispatcher_remove_green(role_object,args1,args2)
    print("remove_green")
    print_r(args2)
end

function GridUnitTest.dispatcher_create_green(role_object,args1,args2)
    print("create_green")
    print_r(args2)
end

function GridUnitTest.dispatcher_create_floor(role_object,args1,args2)
    print("create_floor")
    print_r(args2)
end

function GridUnitTest.dispatcher_remove_floor(role_object,args1,args2)
    print("remove_floor")
    print_r(args2)
end

function GridUnitTest.dispatcher_open_undevelop(role_object,args1,args2)
    print("open_undevelop")
    print_r(args2)
end

function GridUnitTest.dispatcher_promote_undevelop(role_object,args1,args2)
    print("promote_undevelop")
    print_r(args2)
end

function GridUnitTest.dispatcher_finish_undevelop(role_object,args1,args2)
    print("finish_undevelop")
    print_r(args2)
end

function GridUnitTest.dispatcher_add_worker(role_object,args1,args2)
    print("add_worker")
    print_r(args2)
end

function GridUnitTest.dispatcher_get_off_work(role_object,args1,args2)
    print("get_off_work")
    print_r(args2)
end

return GridUnitTest