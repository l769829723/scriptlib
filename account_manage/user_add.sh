#!/bin/bash
USER_NAME=$1
PASSWORD_TMP=$2
EXPIRATION_TIME=$3
if [ -z $USER_NAME ];then
  echo "USER_NAME IS NULL"
  exit 1
fi
if [ -z $PASSWORD_TMP ];then
  echo "PASSWORD_TMP IS NULL"
  exit 2
fi
if [ -z $EXPIRATION_TIME ];then
  echo "EXPIRATION_TIME IS NULL"
  exit 3
fi
useradd ${USER_NAME} -e ${EXPIRATION_TIME}
if [ $? -eq 0 ];then
  echo "ADD USER_NAME[$USER_NAME] SUCCESS!"
else
  echo "ADD USER_NAME[$USER_NAME] FAILURE!"
fi
echo "${PASSWORD_TMP}" | passwd --stdin "${USER_NAME}"
if [ $? -eq 0 ];then
  echo "SET PASSWORD[${PASSWORD_TMP}] SUCCESS!"
else
  echo "SET PASSWORD[${PASSWORD_TMP}] FAILURE!"
fi
