.PHONY: default clean

TOP=$(PWD)
LUA_CLIB_PATH ?= skynet/luaclib
CC ?= gcc
LUA_INC ?= skynet/3rd/lua
CFLAGS = -g -O2 -Wall -I$(LUA_INC)
SHARED := -fPIC --shared
PLAT ?= linux

default : redis/src/redis skynet/skynet $(LUA_CLIB_PATH)/cjson.so $(LUA_CLIB_PATH)/log.so

redis/Makefile:
	git submodule update --init

redis/src/redis : redis/Makefile
	cd $(TOP)
	cd redis && $(MAKE)

skynet/Makefile :
	git submodule update --init

skynet/skynet : skynet/Makefile
	cd $(TOP)
	cd skynet && $(MAKE) $(PLAT)

$(LUA_CLIB_PATH)/cjson.so : 3rd/lua-cjson/lua_cjson.c 3rd/lua-cjson/strbuf.c 3rd/lua-cjson/fpconv.c | $(LUA_CLIB_PATH)
	cd $(TOP)
	$(CC) $(CFLAGS) $(SHARED) -I3rd/lua-cjson $^ -o $@ 

$(LUA_CLIB_PATH)/log.so : 3rd/lua-log/lua-log.c | $(LUA_CLIB_PATH)
	cd $(TOP)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@

clean :
	cd skynet && $(MAKE) clean
