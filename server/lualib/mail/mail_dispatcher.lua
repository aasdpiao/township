local syslog = require "syslog"
local class = require "class"
local print_r = require "print_r"
local skynet = require "skynet"

local MailDispatcher = class()

function MailDispatcher:ctor(role_object)
    self.__role_object = role_object
end

function MailDispatcher:register_c2s_callback(request_name,callback)
    self.__role_object:register_c2s_callback(request_name,callback)
end

function MailDispatcher:init()
    self:register_c2s_callback("read_mail",self.dispatcher_read_mail)
    self:register_c2s_callback("delete_mail",self.dispatcher_delete_mail)
    self:register_c2s_callback("delete_all_read",self.dispatcher_delete_all_read)
    self:register_c2s_callback("receive_mail",self.dispatcher_receive_mail)
    self:register_c2s_callback("request_mail",self.dispatcher_request_mail)

    
end

function MailDispatcher.dispatcher_read_mail(role_object,msg_data)
    local mail_id = msg_data.mail_id
    local mail_ruler = role_object:get_mail_ruler()
    local result = mail_ruler:read_mail(mail_id)
    return {result= result}
end

function MailDispatcher.dispatcher_delete_mail(role_object,msg_data)
    local mail_id = msg_data.mail_id
    local mail_ruler = role_object:get_mail_ruler()
    local result = mail_ruler:delete_mail(mail_id)
    return {result= result}
end

function MailDispatcher.dispatcher_delete_all_read(role_object,msg_data)
    local mail_ruler = role_object:get_mail_ruler()
    local result = mail_ruler:delete_all_read()
    return {result= result}
end

function MailDispatcher.dispatcher_receive_mail(role_object,msg_data)
    local mail_id = msg_data.mail_id
    local item_objects = msg_data.item_objects
    local mail_ruler = role_object:get_mail_ruler()
    local result = mail_ruler:receive_mail(mail_id,item_objects)
    return {result= result}
end

function MailDispatcher.dispatcher_request_mail(role_object,msg_data)
    local mail_ruler = role_object:get_mail_ruler()
    local mail_objects = mail_ruler:dump_mail_objects()
    return {result = 0, mail_objects = mail_objects }
end

return MailDispatcher