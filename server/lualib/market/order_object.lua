local OrderObject = class()

function OrderObject:ctor(role_object,order_entry,item_count)
    self.__role_object = role_object
    self.__order_entry = order_entry
    self.__order_index = order_entry:get_order_index()
    self.__item_count = item_count
    self.__status = 0
end

function OrderObject:dump_order_object()
    local order_object = {}
    order_object.order_index = self.__order_index
    order_object.item_count = self.__item_count
    order_object.status = self.__status
    return order_object
end

return OrderObject

