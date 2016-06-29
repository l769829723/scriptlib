#!/bin/bash
USER_ACCOUNT=$1
if [ -z $USER_ACCOUNT ];then
  echo "USER_ACCOUNT IS NULL"
  exit 1 
fi
userdel -r ${USER_ACCOUNT} &> /dev/null
id -u ${USER_ACCOUNT} &> /dev/null
if [ $? -eq 0 ];then
  echo "DELETE USER_ACCOUNT [${USER_ACCOUNT}] FAILURE!"
else
  echo "DELETE USER_ACCOUNT [${USER_ACCOUNT}] SUCCESS!"
fi
