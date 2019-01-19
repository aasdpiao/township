#!/bin/bash

HOSTNAME="127.0.0.1"
PORT="3306"
USERNAME="township"
PASSWORD="123456"

ACCOUNT_DB="township_accountdb" 
GAME_DB="township_gamedb" 
GLOBAL_DB="township_globaldb" 

delete_sql1="DROP DATABASE ${ACCOUNT_DB}"
delete_sql2="DROP DATABASE ${GAME_DB}"
delete_sql3="DROP DATABASE ${GLOBAL_DB}"

mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} -e "${delete_sql1}"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} -e "${delete_sql2}"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} -e "${delete_sql3}" 
