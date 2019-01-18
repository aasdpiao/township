local consume = {}

function consume_msg(sc)
	if not sc then
		return "nil"
	end
	return consume[sc].desc
end

local function add(con)
	assert(consume[con.code] == nil, string.format("have the same error code[%x], msg[%s]", con.code, con.message))
	consume[con.code] = {desc = con.desc , type = con.type}
	return con.code
end

CONSUME_CODE = {
	no_consume              = add{code = 0x0000, desc = "未标记"},
	buy_item                = add{code = 0x0001, desc = "购买物品"},
	sale_item               = add{code = 0x0002, desc = "出售物品"},
	plant                   = add{code = 0x0003, desc = "种植"},
	promote                 = add{code = 0x0004, desc = "加速"},
	add_slot                = add{code = 0x0005, desc = "增加槽位"},
	unlock                  = add{code = 0x0006, desc = "解锁"},
	build                   = add{code = 0x0007, desc = "建造"},
	undevelop               = add{code = 0x0008, desc = "解锁未开发"},
	market                  = add{code = 0x0009, desc = "市场购买"},
	commodity               = add{code = 0x000a, desc = "市场搜索购买"},
	set_sail                = add{code = 0x000b, desc = "出海"},
	buy_ship                = add{code = 0x000c, desc = "购买船只"},
	finish_order            = add{code = 0x000d, desc = "完成订单"},
	employment_worker       = add{code = 0x000e, desc = "雇佣员工"},
	add_upper               = add{code = 0x000f, desc = "增加上限"},
	refresh                 = add{code = 0x0010, desc = "刷新"},
	employ_businessman      = add{code = 0x0011, desc = "雇佣搜素商人"},
	worker_upgrade          = add{code = 0x0012, desc = "员工进阶"},
	product                 = add{code = 0x0013, desc = "生产"},
	feed                    = add{code = 0x0014, desc = "喂养"},
	help                    = add{code = 0x0015, desc = "帮助"},
}

return consume