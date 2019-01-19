local cjson = require "cjson"
local crypt = require "skynet.crypt"
local base64encode = crypt.base64encode
local base64decode = crypt.base64decode
local cjsonencode = cjson.encode
local cjosndecode = cjson.decode
cjson.encode_sparse_array(true, 1, 1)


local packer = {}

-- function packer.pack (v)
-- 	return base64encode (v)
-- end

-- function packer.unpack (v)
-- 	return base64decode (v)
-- end

function packer.pack (v)
	if not v then return end
	return string.escape(v)
end

function packer.unpack (v)
	return v
end

function packer.encode(v)
	return cjsonencode(v)
end

function packer.decode(v)
	return cjosndecode(v)
end

return packer
