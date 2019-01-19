local class = require "class"

local MailObject = class()

function MailObject:ctor(role_object)
    self.__role_object = role_object
    self.__mail_id = 0 
    self.__title = ""
    self.__content = ""
    self.__timestamp = 0
    self.__item_objects = {}
    self.__status = 0
end

function MailObject:set_mail_object(mail_id,title,content,timestamp,item_objects,status)
    self.__mail_id = mail_id 
    self.__title = title
    self.__content = content
    self.__timestamp = timestamp
    self.__item_objects = item_objects
    self.__status = status or 0
end

function MailObject:dump_mail_object()
    local mail_data = {}
    mail_data.mail_id = self.__mail_id
    mail_data.title = self.__title
    mail_data.content = self.__content
    mail_data.timestamp = self.__timestamp
    mail_data.item_objects = self.__item_objects
    mail_data.status = self.__status
    return mail_data
end

function MailObject:get_mail_id()
    return self.__mail_id
end

function MailObject:check_can_read()
    return self.__status <= 0
end

function MailObject:read_mail()
    if #self.__item_objects > 0 then
        self.__status = 1 
    else
        self.__status = 2
    end  
end

function MailObject:check_can_receive()
    return self.__status <= 1
end

function MailObject:receive_mail()
    for i,v in ipairs(self.__item_objects) do
        local item_index = v.item_index
        local item_count = v.item_count
        self.__role_object:add_item(item_index,item_count,SOURCE_CODE.mail)
    end
    self.__status = 2
end

function MailObject:check_can_delete()
    return self.__status >= 2
end

function MailObject:get_item_objects()
    local item_objects = {}
    for i,v in pairs(self.__item_objects) do
        item_objects[v.item_index] = v.item_count
    end
    return item_objects
end

return MailObject