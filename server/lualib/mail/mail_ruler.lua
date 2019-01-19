local class = require "class"
local packer = require "db.packer"
local MailDispatcher = require "mail.mail_dispatcher"
local MailObject = require "mail.mail_object"
local cjson = require "cjson"
local skynet = require "skynet"

local MailRuler = class()

function MailRuler:ctor(role_object)
    self.__role_object = role_object
end

function MailRuler:init()
    self.__mail_dispatcher = MailDispatcher.new(self.__role_object)
    self.__mail_dispatcher:init()

    self.__mail_seed = 1000
    self.__mail_objects = {}
    self.__global_id = 0
end

function MailRuler:get_mail_id()
    self.__mail_seed = self.__mail_seed + 1
    return self.__mail_seed
end

function MailRuler:load_mail_data(mail_data)
    if not mail_data then return end
    local code = packer.decode(mail_data) 
    local mail_seed = code.mail_seed or 1000
    local global_id = code.global_id or 0
    local mail_objects = code.mail_objects or {}
    self.__mail_seed = mail_seed
    self.__global_id = global_id
    self:load_mail_objects(mail_objects)
end

function MailRuler:load_mail_objects(mail_objects)
    for i,v in ipairs(mail_objects) do
        local mail_id = v.mail_id
        local title = v.title
        local content = v.content
        local timestamp = v.timestamp
        local item_objects = v.item_objects
        local status = v.status
        local mail_object = MailObject.new(self.__role_object)
        mail_object:set_mail_object(mail_id,title,content,timestamp,item_objects,status)
        self.__mail_objects[mail_id] = mail_object
    end
end

function MailRuler:load_golabl_mail(data)
    if not data then return end
    for i,v in ipairs(data) do
        local global_id = v[1]
        if global_id > self.__global_id then
            local title = v[2]
            local content = v[3]
            local timestamp = string2time(v[4])
            local items = cjson.decode(v[5])
            local item_objects = {}
            for i,v in pairs(items) do
                i = tonumber(i)
                v = tonumber(v)
                table.insert( item_objects, {item_index=i,item_count=v})
            end
            local mail_object = MailObject.new(self.__role_object)
            local mail_id = self:get_mail_id()
            mail_object:set_mail_object(mail_id,title,content,timestamp,item_objects)
            self.__mail_objects[mail_id] = mail_object
            self.__global_id = global_id
        end
    end
end

function MailRuler:load_init_mail(data)
    if not data then return end
    for i,v in ipairs(data) do
        local global_id = v[1]
        if global_id > self.__global_id then
            self.__global_id = global_id
        end
    end
end

function MailRuler:get_mail_object(mail_id)
    return self.__mail_objects[mail_id]
end

function MailRuler:dump_mail_data()
    local mail_data = {}
    mail_data.mail_seed = self.__mail_seed
    mail_data.global_id = self.__global_id
    mail_data.mail_objects = self:dump_mail_objects()
    return mail_data
end

function MailRuler:dump_mail_objects()
    local mail_objects = {}
    for k,v in pairs(self.__mail_objects) do
        table.insert( mail_objects, v:dump_mail_object())
    end
    return mail_objects
end

function MailRuler:serialize_mail_data()
    local mail_data = self.dump_mail_data(self)
    return packer.encode(mail_data)
end

function MailRuler:send_mail(mail_data)
    local mail_data = cjson.decode(mail_data)
    local global_id = mail_data.mail_id or self.__global_id
    local title = mail_data.title
    local content = mail_data.content
    local items = cjson.decode(mail_data.item_objects)
    local timestamp = skynet.call("timed","lua","query_current_time")
    local item_objects = {}
    for i,v in pairs(items) do
        i = tonumber(i)
        v = tonumber(v)
        table.insert( item_objects, {item_index=i,item_count=v})
    end
    local mail_object = MailObject.new(self.__role_object)
    local mail_id = self:get_mail_id()
    mail_object:set_mail_object(mail_id,title,content,timestamp,item_objects)
    self.__mail_objects[mail_id] = mail_object
    self.__global_id = global_id
    local msg = {}
    msg.mail_id = mail_id
    msg.title = title
    msg.content = content
    msg.timestamp = timestamp
    msg.status = 0
    msg.item_objects = item_objects
    self.__role_object:send_request("send_mail",msg)
end

function MailRuler:read_mail(mail_id)
    local mail_object = self:get_mail_object(mail_id)
    if not mail_object then 
        LOG_ERROR("mail_id:%d error:%s",mail_id,errmsg(GAME_ERROR.mail_not_exist))
        return GAME_ERROR.mail_not_exist
    end
    if not mail_object:check_can_read() then
        LOG_ERROR("error:%s",errmsg(GAME_ERROR.cant_read_mail))
        return GAME_ERROR.cant_read_mail
    end
    mail_object:read_mail()
    return 0
end

function MailRuler:receive_mail(mail_id,item_objects)
    local mail_object = self:get_mail_object(mail_id)
    if not mail_object then 
        LOG_ERROR("mail_id:%d error:%s",mail_id,errmsg(GAME_ERROR.mail_not_exist))
        return GAME_ERROR.mail_not_exist
    end
    if not mail_object:check_can_receive() then
        LOG_ERROR("error:%s",errmsg(GAME_ERROR.cant_receive_mail))
        return GAME_ERROR.cant_receive_mail
    end
    local items = {}
    for i,v in ipairs(item_objects) do
        items[v.item_index] = v.item_count
    end
    local rewards = mail_object:get_item_objects()
    for k,v in pairs(items) do
        if rewards[k] ~= v then
            LOG_ERROR("item_index:%d item_count:%d count:%d error:%s",k,v,rewards[k] or 0,errmsg(GAME_ERROR.number_not_match))
            return GAME_ERROR.number_not_match
        end
    end
    mail_object:receive_mail()
    return 0
end

function MailRuler:delete_mail(mail_id)
    local mail_object = self:get_mail_object(mail_id)
    if not mail_object then 
        LOG_ERROR("mail_id:%d error:%s",mail_id,errmsg(GAME_ERROR.mail_not_exist))
        return GAME_ERROR.mail_not_exist
    end
    if not mail_object:check_can_delete() then
        LOG_ERROR("error:%s",errmsg(GAME_ERROR.cant_delete_mail))
        return GAME_ERROR.cant_delete_mail
    end
    self.__mail_objects[mail_id] = nil
    return 0
end

function MailRuler:delete_all_read()
    local mail_ids = {}
    for i,v in pairs(self.__mail_objects) do
        if v:check_can_delete() then
            table.insert(mail_ids,v:get_mail_id())
        end
    end
    for i,v in ipairs(mail_ids) do
        self.__mail_objects[v] = nil
    end
    return 0
end

return MailRuler