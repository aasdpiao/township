package.cpath = "skynet/luaclib/?.so"
package.path = "skynet/lualib/?.lua;".."server/lualib/?.lua;".."?.lua"

CLIENT = true

local RoleObject = require("client.role_object")

local token = {
	server = "township",
	user = "zdq",
	pass = "e10adc3949ba59abbe56e057f20f883e",
	request_type = "register"
}

local robot = RoleObject.new(token)
robot:start()

