local SaleObject = class()

function SaleObject:ctor(role_object,sale_entry,item_count)
    self.__role_object = role_object
    self.__sale_entry = sale_entry
    self.__sale_index = sale_entry:get_sale_index()
    self.__item_count = item_count
    self.__status = 0
end

function SaleObject:dump_sale_object()
    local sale_object = {}
    sale_object.sale_index = self.__sale_index
    sale_object.item_count = self.__item_count
    sale_object.status = self.__status
    return sale_object
end

function SaleObject:get_item_index()
    return self.__sale_entry:get_item_index()
end

function SaleObject:get_item_count()
    return self.__item_count
end

function SaleObject:get_sale_price()
    local sale_price = self.__sale_entry:get_sale_price()
    return sale_price * self.__item_count
end

function SaleObject:check_can_buy()
    return self.__status == 0 
end

function SaleObject:buy_sale()
    self.__status = 1
end

function SaleObject:set_status(status)
    self.__status = status
end

return SaleObject

