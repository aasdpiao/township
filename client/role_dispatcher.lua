local class = require("class")
local print_r = require("print_r")

local RoleDispatcher = class()

function RoleDispatcher:ctor()
    self.__c2s_protocal = {}
    self.__s2c_protocal = {}
end

function RoleDispatcher:register_s2c_callback(name,callback)
    self.__s2c_protocal[name] = callback
end

function RoleDispatcher:register_c2s_callback(name,callback)
    self.__c2s_protocal[name] = callback
end

function RoleDispatcher:get_handle_response(name)
    return self.__c2s_protocal[name]
end

function RoleDispatcher:get_handle_request(name)
    return self.__s2c_protocal[name]
end

function RoleDispatcher:init()
    --self:register_s2c_callback("send_mail",self.dispatcher_send_mail)
    -- self:register_s2c_callback("synctime",self.dispatcher_synctime)
    -- self:register_s2c_callback("cmd",self.dispatcher_cmd)
    -- self:register_s2c_callback("pull",self.dispatcher_pull)
    -- self:register_s2c_callback("push",self.dispatcher_push)
    -- self:register_s2c_callback("planting_cropper",self.dispatcher_planting_cropper)
    -- self:register_s2c_callback("harvest_cropper",self.dispatcher_harvest_cropper)
    -- self:register_s2c_callback("promote_plant",self.dispatcher_promote_plant)
end

-- function RoleDispatcher.dispatcher_synctime(role_object,args1,args2)
--     local time_stamp = args2.timestamp
--     role_object:get_time_manager():sync_time(time_stamp)
-- end

-- function RoleDispatcher.dispatcher_cmd(role_object,args1,args2)
--     if args2.result == 0 then
--         print("cmd:"..args1.cmd.." 成功")
--     else
--         print("cmd:"..args1.cmd.." 失败")
--     end
-- end

-- function RoleDispatcher.dispatcher_pull(role_object,args1,args2)
--     print_r(args2)
-- end

-- function RoleDispatcher.dispatcher_planting_cropper(role_object,args1,args2)
--     print_r(args2)   
-- end

-- function RoleDispatcher.dispatcher_harvest_cropper(role_object,args1,args2)
--     print_r(args2)   
-- end

-- function RoleDispatcher:dispatcher_promote_plant(role_object,args1,args2)
--     print_r(args2) 
-- end

return RoleDispatcher

