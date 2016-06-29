#!/usr/bin/env sh

# MQ automic installation script

# author: licy

# 初始化变量
ROOT_DIR=$(cd "$(dirname "$0")"; pwd)
LOG_DIR=$ROOT_DIR/log
TMP_DIR=$ROOT_DIR/tmp
CONFIG_FILE_SYSCTL=$ROOT_DIR/config/sysctl.txt
CONFIG_FILE_LIMITS=$ROOT_DIR/config/limits.txt
CONFIG_FILE_EXPORT=$ROOT_DIR/config/export.txt
LOG_FILE=$LOG_DIR/install.log
BASE_URL="http://192.168.12.4/software/MQServer/WSMQ_8.0.0.4_TRIAL_LNX_ON_X86_64_.tar.gz"


# 下载过程
function download(){
	echo "Downloading package file ..."
	wget -P $ROOT_DIR/v8 $BASE_URL 1>&$LOG_FILE
	echo "Download done, saved in $ROOT_DIR/v8 ."
}


echo "*** WebSphere MQ automic installtion step ***"

# 故障编号 1 安装包不存在 2 解压失败

# 检查文件夹，不存在则创建
if [[ ! -d $LOG_DIR ]]; then
	#statements
	mkdir -p $LOG_DIR
fi

if [[ ! -d $TMP_DIR ]]; then
	#statements
	mkdir -p $TMP_DIR
fi

# 安装包是否存在

PACK_FILE=`ls $ROOT_DIR/v8 |grep "WSMQ_8.0.0.4_TRIAL_LNX_ON_X86_64_.tar.gz"`

if [[ ! -n $PACK_FILE ]]; then
	#statements
	echo "MQ package is not exsits, will download."
	download;
	PACK_FILE=`ls $ROOT_DIR/v8 |grep "WSMQ_8.0.0.4_TRIAL_LNX_ON_X86_64_.tar.gz"`
else
	echo "MQ package is found, in $ROOT_DIR/v8 ."
fi

# 安装前准备 #
# 创建用户和组
# GROUP=mqm
USER=mqadmin
groupadd -f mqm
if [[ `grep $USER /etc/passwd` = "" ]]; then
	#statements
	useradd -m -g mqm -G root $USER -p password
fi
# useradd -m -g mqm -G root mqadmin -p password
echo mqadmin:password |chpasswd
usermod -G mqm root

# 解包
echo "The file $PACK_FILE is unpaking now ..."
tar zxvf $ROOT_DIR/v8/$PACK_FILE -C $TMP_DIR >>$LOG_FILE
cd $TMP_DIR/*/

if [[ ! $? = 0 ]]; then
	#statements
	echo "Unpaked failed."
	exit 2
else
	echo "Unpack done."
fi

# 接受安装许可证
echo "Accepted the installation license."
sh mqlicense.sh -accept &>>$LOG_FILE

# 开始安装
echo "Starting installation setp."
rpm -ivh *.rpm &>>$LOG_FILE

# 配置
echo "Modify sysctl configuration."

while read line ; do
	#statements
	echo $line >> /etc/sysctl.conf
done < $CONFIG_FILE_SYSCTL

# 临时关闭通配符 #
set -f
echo "Modify Linux kernel limits"
while read line ; do
	#statements
	echo $line >> /etc/security/limits.conf
done < $CONFIG_FILE_LIMITS
set +f
# 结束 #

# 设置系统环境变量
echo "Export system enviroment variables."

while read line ; do
	#statements
	echo $line >> /home/mqadmin/.bash_profile
done < $CONFIG_FILE_EXPORT

# 安装完成
echo "Remove installation file ..."

cd ~/
rm -rf $ROOT_DIR

echo "*** Automic installation MQ done ***"