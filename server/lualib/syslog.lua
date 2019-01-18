local skynet = require "skynet"

local syslog = {
	prefix = {
		"D|",
		"I|",
		"N|",
		"W|",
		"E|",
	},
}

local level = 1 -- 1:debug 2:info 3:notice 4:warning 5:error

local function write (priority, fmt, ...)
	if not fmt then return end
	if priority >= level then
		skynet.error (syslog.prefix[priority] .. fmt, ...)
	end
end

local function writef (priority, ...)
	if priority >= level then
		skynet.error (syslog.prefix[priority] .. string.format (...))
	end
end

function syslog.debug (...)
	write (1, ...)
end

function syslog.debugf (...)
	writef (1, ...)
end

function syslog.info (...)
	write (2, ...)
end

function syslog.infof (...)
	writef (2, ...)
end

function syslog.notice (...)
	write (3, ...)
end

function syslog.noticef (...)
	writef (3, ...)
end

function syslog.warning (...)
	write (4, ...)
end

function syslog.warningf (...)
	writef (4, ...)
end

function syslog.err (...)
	write (5, ...)
end

function syslog.errf (...)
	writef (5, ...)
end

return syslog
