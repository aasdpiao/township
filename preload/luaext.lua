function math.round(num)
    return math.floor(num + 0.5)
end

function math.pow(num, n)
    return num ^ n
end

function tonum(v, base)
    return tonumber(v, base) or 0
end

function toint(v)
    return math.round(tonum(v))
end

function tobool(v)
    return (v ~= nil and v ~= false)
end

function totable(v)
    if type(v) ~= "table" then v = {} end
    return v
end

function array_totable(array)
    if not array then
        return nil
    end
    array = totable(array)
    local tb = {}
    for i=1,#array,2 do
        tb[array[i]] = array[i+1]
    end
    return tb
end

function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function copy(object)
    if not object then return object end
    local new = {}
    for k, v in pairs(object) do
        local t = type(v)
        if t == "table" then
            new[k] = copy(v)
        elseif t == "userdata" then
            new[k] = copy(v)
        else
            new[k] = v
        end
    end
    return new
end

function string.split(str, delimiter)
    str = tostring(str)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(str, delimiter, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end

function string.ltrim(str)
    return string.gsub(str, "^[ \t\n\r]+", "")
end

function string.rtrim(str)
    return string.gsub(str, "[ \t\n\r]+$", "")
end

function string.trim(str)
    str = string.gsub(str, "^[ \t\n\r]+", "")
    return string.gsub(str, "[ \t\n\r]+$", "")
end

function string.ucfirst(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

local function urlencodeChar(char)
    return "%" .. string.format("%02X", string.byte(c))
end

function string.urlencode(str)
    str = string.gsub(tostring(str), "\n", "\r\n")
    str = string.gsub(str, "([^%w%.%- ])", urlencodeChar)
    return string.gsub(str, " ", "+")
end

function string.urldecode(str)
    str = string.gsub (str, "+", " ")
    str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonum(h,16)) end)
    str = string.gsub (str, "\r\n", "\n")
    return str
end

function string.utf8len(str)
    local len  = #str
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(str, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function string.utf8sub(str, start, last)
    if start > last then
        return ""
    end
    local len  = #str
    local left = len
    local cnt  = 0
    local startByte = len + 1
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(str, -left)
        local i   = #arr        
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
        if cnt == start then
            startByte = len - (left + i) + 1
        end
        if cnt == last then
            return string.sub(str, startByte, len - left)
        end
    end
    return string.sub(str, startByte, len)
end

local mode = "[%z\'\"\\\26\b\n\r\t]"
local replace = {
    ['\0']='\\0',
    ['\''] = '\\\'',
    ['\"'] = '\\\"',
    ['\\'] = '\\\\',
    ['\26'] = '\\z',
    ['\b'] = '\\b',
    ['\n'] = '\\n',
    ['\r'] = '\\r',
    ['\t'] = '\\t',
}

function string.escape(s)
    return string.gsub(s, mode, replace)
end

function table.empty(t)
	return _G.next(t) == nil
end

function table.nums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.keys(t)
    local keys = {}
    for k, v in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

function table.values(t)
    local values = {}
    for k, v in pairs(t) do
        values[#values + 1] = v
    end
    return values
end

function table.zero(t, len)
    assert(type(t) == "table")
    for i=1, len do
        t[i] = 0
    end
end

function table.malloc(len)
    local t = {}
    table.zero(t, len)
    return t
end

function table.toarray(tb)
    if type(tb) ~= "table" then return nil end
    local info = {}
    for k, v in pairs(tb) do
        info[#info+1] = k
        info[#info+1] = v
    end
    return info
end

function table.tostring(root)
    if root == nil then
        return "nil"
    elseif type(root) == "number" then
        return tostring(root)
    elseif type(root) == "string" then
        return root
    end
    local cache = {  [root] = "." }
    local function _dump(t,space,name)
        local temp = {}
        for k,v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                table.insert(temp,"+" .. key .. " {" .. cache[v].."}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                table.insert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. string.rep(" ",#key),new_key))
            else
                if type(v) == "string" then
                    table.insert(temp,"+" .. key .. " [\"" .. tostring(v).."\"]")
                else
                    table.insert(temp,"+" .. key .. " [" .. tostring(v).."]")
                end
                
            end
        end
        return table.concat(temp,"\n"..space)
    end
    return (_dump(root, "",""))
end

function get_epoch_time(epoch_time)
    return os.date("%c",epoch_time)
end

function string2time(timeString)
    if type(timeString) ~= 'string' then error('string2time: timeString is not a string') return 0 end
    local fun = string.gmatch( timeString, "%d+")
    local y = fun() or 0
    if y == 0 then error('timeString is a invalid time string') return 0 end
    local m = fun() or 0
    if m == 0 then error('timeString is a invalid time string') return 0 end
    local d = fun() or 0
    if d == 0 then error('timeString is a invalid time string') return 0 end
    local H = fun() or 0
    if H == 0 then error('timeString is a invalid time string') return 0 end
    local M = fun() or 0
    if M == 0 then error('timeString is a invalid time string') return 0 end
    local S = fun() or 0
    if S == 0 then error('timeString is a invalid time string') return 0 end
    return os.time({year=y, month=m, day=d, hour=H,min=M,sec=S})
end

