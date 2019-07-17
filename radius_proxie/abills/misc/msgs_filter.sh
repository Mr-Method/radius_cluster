#!/bin/sh
# Message filter managment script
# Add, del filters

version=0.5
DEBUG=1;
IP=$1;
LOG=1;

SSH=`which ssh`;

BILLING_DIR="/usr/abills/";

DB_USER=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbuser}' |awk -F"\'" '{print $2}'`
DB_PASSWD=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbpasswd}' |awk -F"\'" '{print $2}'`
DB_NAME=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbname}' |awk -F"\'" '{print $2}'`
DB_HOST=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbhost}' |awk -F"\'" '{print $2}'`
DB_CHARSET=`cat ${BILLING_DIR}/libexec/config.pl |grep '^$conf{dbcharset}' |awk -F"\'" '{print $2}'`

MYSQL=`which mysql`;


if [ x"${MYSQL}" = x ]; then
  MYSQL=/usr/local/bin/mysql
fi;

MSGS_TABLE_NUM=100

if [ w$1 = w ]; then
  echo "Add arguments";
  exit
fi;

ACTION=$1
UID=$2

#OS
OS=`uname`;

#************************************************
#
#************************************************
get_online_info () {

  SQL="SELECT INET_NTOA(c.framed_ip_address), n.nas_type AS nas_type,
    n.mng_host_port, n.mng_user  FROM dv_calls c
    INNER JOIN nas n ON (n.id=c.nas_id) 
    WHERE c.framed_ip_address=INET_ATON('${IP}');";

  OUTPUT=`${MYSQL} -N -h "${DB_HOST}" -D "${DB_NAME}" -p"${DB_PASSWD}" -u ${DB_USER} -e "${SQL}"`;

  for LINE in "${OUTPUT}"; do
  
    IP=`echo ${LINE} | awk '{ print $1 }'`;
    NAS_TYPE=`echo ${LINE} | awk '{ print $2 }'`;
    HOST_IP_PORT=`echo ${LINE} | awk '{ print $3 }'`;
    USER_NAME=`echo ${LINE} | awk '{ print $4 }'`;

    if [ x"${NAS_TYPE}" = x'mikrotik' ]; then
      mikrotik_skip ${HOST_IP_PORT} ${USER_NAME}
    else
      os_skip ${HOST_IP_PORT} ${USER_NAME}
    fi;

  done;
}

#************************************************
#
#************************************************
mikrotik_skip () {
  HOST=$1
  USER_NAME=$2

  PORT=`echo ${HOST} | awk -F: '{ print $3 }'`
  HOST=`echo ${HOST} | awk -F: '{ print $1 }'`

  if [ w"${PORT}" = w ]; then
    PORT=22;
  fi;

  if [ x"${DEBUG}" != x ]; then
    echo "Mikrotik: ${HOST} User: ${USER_NAME}";
  fi;

  CMD=${CMD}"${SSH} -p ${PORT} -o ConnectTimeout=10 -i /usr/abills/Certs/id_dsa.${USER_NAME} ${USER_NAME}@${HOST} \"/ip firewall address-list remove [find address=${IP}]\"; ";
  
  echo ${CMD};
}


#************************************************
#
#************************************************
os_skip () {
if [ x"${OS}" = x"FreeBSD" ]; then
  #Add online filter
  if [ w"${ACTION}" = wadd ]; then
    SQL="SELECT INET_NTOA(framed_ip_address) AS ip from dv_calls WHERE uid IN (${UID});";
    OUTPUT=`${MYSQL} -N -h ${DB_HOST} -D ${DB_NAME} -p"${DB_PASSWD}" -u ${DB_USER} -e "${SQL}"`;

    for LINE in ${OUTPUT}; do
      IP=`echo ${LINE} | awk '{ print $1 }'`;
   #   UID=`echo ${LINE} | awk '{ print $2 }'`;
   
      if [ "${IP}" != 'ip' ]; then
        if [ w${DEBUG} != w ]; then
          echo "/sbin/ipfw table ${MSGS_TABLE_NUM} add ${IP} ${UID}";
        fi;

        /sbin/ipfw table ${MSGS_TABLE_NUM} add ${IP} ${UID}
      fi;
    
    done;
  # Del redirect  
  else 
    if [ w${DEBUG} != w ]; then
      echo "IP deleted - ${IP}"
    fi;
    /sbin/ipfw table ${MSGS_TABLE_NUM} delete ${IP}
  fi;

else
#If OS linux


fi;
}



get_online_info

${CMD}
if [ x${LOG} != x ]; then
  echo "${CMD}" >> /tmp/skip_warning
fi;

#Multiservers starter
##!/bin/sh#
#
#ACTION=$1
#UID=$2
#IP=$3
#
#echo "${ACTION} ${UID}"
#
#for host in 192.168.17.2 192.168.17.4; do
#
#if [ "${ACTION}" = "add" ]; then
#  /usr/bin/ssh -i /usr/abills/Certs/id_dsa.abills_admin -o StrictHostKeyChecking=no -q abills_admin@${host}  "/usr/local/bin/sudo /usr/abills/misc/msgs_filter.sh ${ACTION} ${UID}"
#else
#  /usr/bin/ssh -i /usr/abills/Certs/id_dsa.abills_admin -o StrictHostKeyChecking=no -q abills_admin@${host} "/usr/local/bin/sudo /usr/abills/misc/msgs_filter.sh
# ${IP}";
#fi;
#
#done;
