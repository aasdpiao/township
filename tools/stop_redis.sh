#!/bin/bash

ps aux|grep redis-server|awk '{print $2}'|xargs kill -9
