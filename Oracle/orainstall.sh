#!/bin/bash

# author:licy

set -e

# 初始化变量
ROOT_DIR=$(cd "$(dirname "$0")"; pwd)
LOG_DIR=$ROOT_DIR/log
CONF_DIR=$ROOT_DIR/config

RPM_DIR=$ROOT_DIR/packages

# oracle
INSTALL_PATH=/opt/oracle

PACK_DIR=$ROOT_DIR/data
CONFIG_FILE_SYSCTL=$ROOT_DIR/config/sysctl.txt
CONFIG_FILE_LIMITS=$ROOT_DIR/config/limits.txt
CONFIG_FILE_EXPORT=$ROOT_DIR/config/export.txt
LOG_FILE=$LOG_DIR/install.log

# User and Group
INSTALLGROUP=oinstall
DBAGROUP=dba
DBAUSER=oracle

# Directory if not exists, make it.
if [ ! -d $LOG_DIR ]; then
	mkdir -p $LOG_DIR
fi

if [ ! -d $INSTALL_PATH ]; then
	mkdir $INSTALL_PATH
fi

if [ ! -d $PACK_DIR ]; then
	mkdir $PACK_DIR
fi

echo "*** Automic installation process starting ... ***"

# Configuration repo source.
echo "Configuration depends on the environment."
cat >/etc/yum.repos.d/oracle.repo<<EOF
[oracle]
name=Oracle package depends
baseurl=file://$RPM_DIR
o=os
gpgcheck=0
enalbled=1
EOF
yum clean all >>$LOG_FILE
yum makecache >>$LOG_FILE
echo "Saved repo file oracle.repo to /etc/yum.repos.d/ ."

echo "In the current environment installation depend on the package."
yum install -y --setopt=protected_multilib=false binutils compat-libstdc++-33 compat-libstdc++-33.i686 >>$LOG_FILE
yum install -y --setopt=protected_multilib=false elfutils-libelf elfutils-libelf-devel gcc gcc-c++ glibc >>$LOG_FILE
yum install -y --setopt=protected_multilib=false glibc.i686 glibc-common glibc-devel glibc-devel.i686 >>$LOG_FILE
yum install -y --setopt=protected_multilib=false glibc-headers ksh libaio libaio.i686 libaio-devel >>$LOG_FILE
yum install -y --setopt=protected_multilib=false libaio-devel.i686 libgcc libgcc.i686 libstdc++ >>$LOG_FILE
yum install -y --setopt=protected_multilib=false libstdc++.i686 libstdc++-devel make sysstat >>$LOG_FILE
yum install -y --setopt=protected_multilib=false unixODBC unixODBC.i686 unixODBC-devel >>$LOG_FILE
yum install -y --setopt=protected_multilib=false unixODBC-devel.i686 >>$LOG_FILE
echo "Depend on the package installation is complete."

# Package file if not exists, download it.
if [ ! -f $PACK_DIR/*.gz ]; then
	echo "Downloading file from http://192.168.170.2/ ."
	wget -P $PACK_DIR http://192.168.170.2/isoshare/linux.x64_11gR2_database.tar.gz >>$LOG_FILE
	echo "Download completed, save in $PACK_DIR ."
	PACK_FILE=$(ls $PACK_DIR |egrep *.gz)
else
	echo "The package file is found ."
	PACK_FILE=$(ls $PACK_DIR |egrep *.gz)
fi

# Create user and group
if [ ! $(grep oinstall /etc/group) ];then
	echo "Installation group not found, will create."
	groupadd $INSTALLGROUP
	echo "Installation group created, $INSTALLGROUP ."
fi

if [ ! $(grep dba /etc/group) ]; then
	echo "Database administrator gorup not found, will create."
	groupadd $DBAGROUP
	echo "Database administrator gorup created, $DBAGROUP ."
fi

if [ ! $(grep oracle /etc/passwd) ]; then
	echo "Database administrator not found, will create."
	useradd -g $DBAGROUP -G $INSTALLGROUP $DBAUSER
	echo "Database administrator created, $DBAUSER ."
fi

# Change user password
echo "$DBAUSER:password" | chpasswd

TMP_DIR=/home/$DBAUSER

# Unpack installation package file.
echo "Unpack the package is now."
tar zxvf $PACK_DIR/$PACK_FILE -C $TMP_DIR >>$LOG_FILE
if [ ! $? = 0 ]; then
	echo "Unpack failed, please retry."
fi

# Modify system configuration
echo "Modify system kernel sysctl configuration."

while read line ; do
	#statements
	echo $line >> /etc/sysctl.conf >>$LOG_FILE
done < $CONFIG_FILE_SYSCTL
/sbin/sysctl -p

echo "Modify user $DBAUSER shell limits."
while read line ; do
	#statements
	echo $line >> /etc/security/limits.conf >>$LOG_FILE
done < $CONFIG_FILE_LIMITS

# Chanage user login pam
echo "Modify user $DBAUSER login authentication."
cat >>/etc/pam.d/login<<EOF
session required /lib/security/pam_limits.so
session required pam_limits.so
EOF

echo "Modify user $DBAUSER login profile."
cat >>/etc/profile<<EOF
if [ $USER = "$DBAUSER" ]; then
	if [ $SHELL = "/bin/ksh" ]; then
		ulimit -p 16384
		ulimit -n 65536
	else
		ulimit -u 16384 -n 65536
	fi
fi
EOF
source /etc/profile

echo "Take directory permission grant to $DBAUSER ."
chown -R $DBAUSER:$INSTALLGROUP $INSTALL_PATH
chmod -R 775 $INSTALL_PATH

echo "Create oracle inventory file."
cat >/etc/oraInst.loc<<EOF
inventory_loc=$INSTALL_PATH/oraInventory
inst_group=$INSTALLGROUP
EOF

chown $DBAUSER:$INSTALLGROUP /etc/oraInst.loc
chmod 664 /etc/oraInst.loc

echo "Modify user $DBAUSER enviroments variable."
cat >>/home/$DBAUSER/.bash_profile<<EOF
export ORACLE_BASE=$INSTALL_PATH
export ORACLE_SID=orcl
EOF

echo "Take response file permission grant to $DBAUSER ."
mkdir -p $TMP_DIR/etc
cp -f $CONF_DIR/db_install.rsp $TMP_DIR/etc
chown $DBAUSER:$INSTALLGROUP $TMP_DIR/etc/*.rsp
chmod 700 $TMP_DIR/etc/*.rsp


echo "Change installation response file."
sed -i "s/ORACLE_HOSTNAME=/ORACLE_HOSTNAME=$HOSTNAME/g" $TMP_DIR/etc/db_install.rsp
sed -i "s/UNIX_GROUP_NAME=/UNIX_GROUP_NAME=$INSTALLGROUP/g" $TMP_DIR/etc/db_install.rsp
sed -i "s:INVENTORY_LOCATION=:INVENTORY_LOCATION=$INSTALL_PATH/oraInventory:g" $TMP_DIR/etc/db_install.rsp
sed -i "s:ORACLE_HOME=:ORACLE_HOME=$INSTALL_PATH/product/11.2.0/db_1:g" $TMP_DIR/etc/db_install.rsp
sed -i "s:ORACLE_BASE=:ORACLE_BASE=$INSTALL_PATH:g" $TMP_DIR/etc/db_install.rsp
sed -i "s:oracle.install.db.DBA_GROUP=:oracle.install.db.DBA_GROUP=$DBAGROUP:g" $TMP_DIR/etc/db_install.rsp
sed -i "s:oracle.install.db.OPER_GROUP=:oracle.install.db.OPER_GROUP=$INSTALLGROUP:g" $TMP_DIR/etc/db_install.rsp
sed -i "s:oracle.install.db.config.starterdb.password.ALL=:oracle.install.db.config.starterdb.password.ALL=$DBAUSER:g" $TMP_DIR/etc/db_install.rsp

echo "Start installation, running up."
su - $DBAUSER -c "$TMP_DIR/database/runInstaller -silent -ignorePrereq -responseFile $TMP_DIR/etc/db_install.rsp" >$LOG_FILE
if [ ! $? = 0 ]; then
	echo "The installation step failed."
	exit 3
	# 3 -> Install failed.
fi

# Watching the installation process.
running=true
while ($running); do
	#statements
	sleep 10
	printf "."
	if [ -f $INSTALL_PATH/oraInventory/logs/*.out ]; then
		if [[ $(grep "Successfully" $INSTALL_PATH/oraInventory/logs/*.out) ]]; then
			echo -e "\n\n*** Automic installation successfull. ***"
			running=false
		fi
	fi
	if [ -f $INSTALL_PATH/oraInventory/log/*.err ]; then
		if [ $(cat $INSTALL_PATH/oraInventory/logs/*.err) ];then
			echo -e "\n\n*** Automic installation failed. ***"
			exit 2
		fi
	fi
done

echo "Run the configuration script on the installation later."
# sh $INSTALL_PATH/oraInventory/orainstRoot.sh <<EOF
#
# EOF
ROOTSH=$(grep "root.sh" $INSTALL_PATH/oraInventory/logs/*.out)
bash $ROOTSH >>$LOG_FILE

echo "Modify user $DBAUSER enviroments variable again."
cat >>/home/$DBAUSER/.bash_profile<<EOF
export ORACLE_HOME=$INSTALL_PATH/product/11.2.0/db_1
export TNS_ADMIN=\$ORACLE_HOME/network/admin
export PATH=.:\${PATH}:\$HOME/bin:\$ORACLE_HOME/bin
export PATH=\${PATH}:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$ORACLE_HOME/lib
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\$ORACLE_HOME/oracm/lib
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/JRE
export CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/JRE/lib
export CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/jlib
export CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/rdbms/jlib
export CLASSPATH=\${CLASSPATH}:\$ORACLE_HOME/network/jlib
export LIBPATH=\${CLASSPATH}:\$ORACLE_HOME/lib:\$ORACLE_HOME/ctx/lib
export ORACLE_OWNER=\$DBAUSER
export SPFILE_PATH=\$ORACLE_HOME/dbs
export ORA_NLS10=\$ORACLE_HOME/nls/data
EOF
source /home/$DBAUSER/.bash_profile
echo "The last configuration is completed for this."
exit 0