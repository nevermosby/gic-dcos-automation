#!/bin/sh

token=$(curl -X GET -H "username: username" -H "password: username" -H "Cache-Control: no-cache" "http://api.yun-idc.com/gic/v1/get_token/" | python -m json.tool | grep "Token" | awk -F'"' '{print $4}')

#echo "Got token: $token"

curl -X GET -H "token: $token" -H "Cache-Control: no-cache" "http://api.yun-idc.com/gic/v1/app/info/?app_id=$1"
