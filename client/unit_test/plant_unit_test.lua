local class = require("class")
local print_r = require("print_r")

local PlantUnitTest = class()

function PlantUnitTest:ctor(role_object)
    self.__role_object = role_object
    self.__socket_client = role_object:get_socket_client()
    self.__role_dispatcher = role_object:get_role_dispatcher()
end

function PlantUnitTest:start_unit_test()
    self:register_s2c_callback()
    self.__socket_client:send_request("planting_cropper",{
        plant_objects = {
            {
                timestamp = self.__time_manager:get_current_time(),
                build_id=1001001,
                plant_index=1001
            }
        }
    })
    self.__socket_client:send_request("promote_plant",{
        timestamp = self.__time_manager:get_current_time(),
        build_id=1001001,
        cash_count=1
    })
    self.__socket_client:send_request("harvest_cropper",{
        plant_objects = {
            {
                timestamp = self.__time_manager:get_current_time(),
                build_id=1001001
            }
        }
    })
end

function PlantUnitTest:register_s2c_callback()
    self.__role_dispatcher:register_s2c_callback("planting_cropper",self.dispatcher_planting_cropper)
    self.__role_dispatcher:register_s2c_callback("promote_plant",self.dispatcher_promote_plant)
    self.__role_dispatcher:register_s2c_callback("harvest_cropper",self.dispatcher_harvest_cropper)
end

function PlantUnitTest.dispatcher_planting_cropper(role_object,args1,args2)
    print("planting_cropper")
    print_r(args2)
end

function PlantUnitTest.dispatcher_promote_plant(role_object,args1,args2)
    print("promote_plant")
    print_r(args2)
end

function PlantUnitTest.dispatcher_harvest_cropper(role_object,args1,args2)
    print("harvest_cropper")
    print_r(args2)
end

return PlantUnitTest