local class = require "class"

local EventObject = class()

function EventObject:ctor(role_object,event_id)
    self.__role_object = role_object
    self.__event_id = event_id
    self.__person_index = 0
    self.__order_index = 0
end

function EventObject:load_event_object(event_object)
    self.__event_id = event_object.event_id
    self.__order_index = event_object.order_index
    self.__person_index = event_object.person_index
end

function EventObject:dump_event_object()
    local event_object = {}
    event_object.event_id = self.__event_id
    event_object.person_index = self.__person_index
    event_object.order_index = self.__order_index
    return event_object
end

function EventObject:get_person_index()
    return self.__person_index
end

function EventObject:set_order_index(order_index)
    self.__order_index = order_index
end

function EventObject:set_person_index(person_index)
    self.__person_index = person_index
end

function EventObject:get_event_entry()
    local event_ruler = self.__role_object:get_event_ruler()
    local event_manager = event_ruler:get_event_manager()
    return event_manager:get_event_entry(self.__order_index)
end

return EventObject