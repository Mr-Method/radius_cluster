#!/bin/bash
# ABillS Firefall Managment Program for Linux
#
#***********************************************************************
# /etc/rc.conf
#
#####Включить фаервол#####
#abills_firewall="YES"
#
#####Включить старый шейпер#####
#abills_shaper_enable="YES"
#
#####Включить новый шейпер#####
#abills_shaper2_enable="YES"
#
#####Включить шейпер IPMARK#####
#abills_shaper3_enable="YES"
#
#####Указать номера нас серверов модуля IPN#####
#abills_ipn_nas_id=""
#
#####Включить NAT "Внешний_IP:подсеть;Внешний_IP:подсеть;"#####
#abills_nat=""
#
#####Втлючть FORWARD на определённую подсеть#####
#abills_ipn_allow_ip=""
#
#####Пул перенаправления на страницу заглушку#####
#abills_redirect_clients_pool=""
#
#####Внутренний интерфейс (нужен для нового шейпера)#####
#####Пример "vlan2,vlan10,vlan20-30,vlan40"#####
#abills_ipn_if=""
#
#####Включить IPoE шейпер#####
#abills_dhcp_shaper="YES"
#
#####Указать ID IPoE NAS серверов#####
#####Пример "10-20,31,26-44"#####
#abills_dhcp_shaper_nas_ids="";
#
#####Указать подсети IPoE серверов доступа#####
#abills_allow_dhcp_port_67=""
#
#####Ожидать загрузку сервера с базой#####
#abills_mysql_server_status="YES"
#
#####Указать адрес сервера mysql#####
#abills_mysql_server=""
#
#####Привязать серевые интерфейсы к ядрам#####
#abills_irq2smp="YES"
#
#####IP Unnumbered#####
#####Указать общую подсеть раздаваемую абонентам#####
#abills_unnumbered="YES"
#
#####Указать общую подсеть раздаваемую абонентам "сеть1;сеть2"#####
#abills_unnumbered_net=""
#
#####Указать шлюз сети для абонентов "шлюз1;шлюз2"#####
#abills_unnumbered_gw=""
#
#####Указать внутриниие интерфейсы#####
#####Пример "vlan2,vlan10,vlan20-30,vlan40"#####
#abills_unnumbered_iface=""
#
#####iptables custom rules
#
# abills_iptables_custom="/etc/fw.conf"
# 
#Load to start System
#sudo update-rc.d shaper_start.sh start 99 2 3 4 5 . stop 01 0 1 6 .
#
#Unload to start System
#sudo update-rc.d -f shaper_start.sh remove
#
### BEGIN INIT INFO
# Provides:          shaper_start
# Required-Start:    $remote_fs $network $syslog
# Should-Start:      $time mysql slapd postgresql samba krb5-kdc
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Radius Daemon
# Description:       Extensible, configurable radius daemon
### END INIT INFO

set -e

if [ -f /lib/lsb/init-functions ]; then
  . /lib/lsb/init-functions
fi;

PROG="shaper_start"
DESCR="shaper_start"
VERSION=1.16

: ${abills_shaper_enable="NO"}
: ${abills_shaper_if=""}
: ${abills_nas_id=""}
: ${abills_ip_sessions=""}

: ${abills_nat=""}
: ${abills_multi_gateway=""}

: ${abills_dhcp_shaper="NO"}
: ${abills_dhcp_shaper_log=""}
: ${abills_dhcp_shaper_nas_ids=""}
: ${abills_neg_deposit="NO"}
: ${abills_neg_deposit_speed=""}
: ${abills_neg_deposit_fwd_ip="127.0.0.1"}
: ${abills_portal_ip="me"}
: ${abills_mikrotik_shaper=""}
: ${abills_squid_redirect="NO"}
: ${firewall_type=""}

: ${abills_ipn_nas_id=""}
: ${abills_ipn_if=""}
: ${abills_ipn_allow_ip=""}

: ${abills_netblock="NO"}
: ${abills_netblock_redirect_ip=""}
: ${abills_netblock_type=""}

#Extra functions
: ${abills_mysql_server_status="NO"}
: ${abills_mysql_server=""}
: ${abills_unnumbered="NO"}
: ${abills_unnumbered_net=""}
: ${abills_unnumbered_iface=""}
: ${abills_unnumbered_gw=""}
: ${abills_irq2smp="NO"}
: ${abills_redirect_clients_pool=""}
: ${abills_iptables_custom=""}
: ${abills_shaper2_enable="NO"}
: ${abills_shaper3_enable="NO"}
: ${abills_allow_dhcp_port_67=""}
: ${abills_firewall=""}

if [ ! -f /etc/rc.conf ]; then
  echo "Please make configuration file: /etc/rc.conf";
  exit;
fi;

if [ -f /etc/rc.conf ]; then
  . /etc/rc.conf
fi;

name="abills_shaper" 

if [ "${abills_shaper_enable}" = "" ]; then
  name="abills_nat"
  abills_nat_enable=YES; 
fi;

TC="/sbin/tc"
IPT=/sbin/iptables
IPSET=`which ipset`;
IPT_RESTORE=/sbin/iptables-restore
SED=/bin/sed 
BILLING_DIR=/usr/abills

#Negative deposit forward (default: )
FWD_WEB_SERVER_IP=127.0.0.1;
#Your user portal IP 
USER_PORTAL_IP=${abills_portal_ip} 
EXTERNAL_INTERFACE=`/sbin/ip r | head -1 | awk '/default/{print $5}'`



#**********************************************************
#
#**********************************************************
all_rulles(){
  ACTION=$1

if [ "${abills_ipn_if}" != "" ]; then
IPN_INTERFACES="";
ifaces=`echo ${abills_ipn_if} | sed 'N;s/\n/ /' |sed 's/,/ /g'`
  for i in ${ifaces}; do
    if [[ ${i} =~ - ]]; then
      vlan_name=`echo ${i}|sed 's/vlan//'`
      IFS='-' read -a start_stop <<< "${vlan_name}"
      for cur_iface in `seq ${start_stop[0]} ${start_stop[1]}`; do
        IPN_INTERFACES="$IPN_INTERFACES vlan${cur_iface}"
      done
    else
      IPN_INTERFACES="$IPN_INTERFACES $i"
    fi
  done
fi;

if [ "${abills_dhcp_shaper_nas_ids}" != "" ]; then
  NAS_IDS="NAS_IDS=";
  nas_ids=`echo ${abills_dhcp_shaper_nas_ids} | sed 'N;s/\n/ /' |sed 's/,/ /g'`
  for i in ${nas_ids}; do
    if [[ ${i} =~ - ]]; then
      IFS='-' read -a start_stop <<< "$i"
      for cur_nas_id in `seq ${start_stop[0]} ${start_stop[1]}`; do
        NAS_IDS="${NAS_IDS}${cur_nas_id};"
      done
    else
      NAS_IDS="${NAS_IDS}${i};"
    fi
  done
fi;

#Enable forwarding
sysctl -w net.ipv4.ip_forward=1

ip_unnumbered
check_server
abills_iptables
abills_nat
abills_shaper
abills_shaper2
abills_shaper3
abills_ipn
abills_dhcp_shaper
neg_deposit
irq2smp
iptables_custom

}

#**********************************************************
#
#**********************************************************
iptables_custom () {
  
  if [ "${abills_iptables_custom}" = "" ]; then
    return 0;
  fi;
  
  if [ -f ${abills_iptables_custom} ]; then
    echo "Load custom iptables rules";
    ${IPT_RESTORE} < ${abills_iptables_custom}
    echo "Custom rules loaded";
  fi;
  
}


#**********************************************************
#IPTABLES RULES
#**********************************************************
abills_iptables() {

if [ x${abills_firewall} = x ]; then
  return 0;
fi;

echo "ABillS Iptables ${ACTION}"

if [ "${ACTION}" = "start" ];then
  ${IPT} -P INPUT DROP
  ${IPT} -P OUTPUT ACCEPT
  ${IPT} -P FORWARD ACCEPT
  ${IPT} -t nat -I PREROUTING -j ACCEPT
  # Включить на сервере интернет
  ${IPT} -A INPUT -i lo -j ACCEPT
  # Пропускать все уже инициированные соединения, а также дочерние от них
  ${IPT} -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
  # Разрешить SSH запросы к серверу
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 7022 -j ACCEPT
  # Разрешить TELNET запросы к серверу
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 23 -j ACCEPT
  # Разрешить ping к серверу доступа
  ${IPT} -A INPUT -p icmp -m icmp --icmp-type any -j ACCEPT
  # Разрешить DNS запросы к серверу
  ${IPT} -A INPUT -p UDP -s 0/0  --sport 53 -j ACCEPT
  ${IPT} -A INPUT -p UDP -s 0/0  --dport 53 -j ACCEPT
  # Разрешить DHCP запросы к серверу
  ${IPT} -A INPUT -p UDP -s 0/0  --sport 68 -j ACCEPT
  ${IPT} -A INPUT -p UDP -s 0/0  --dport 68 -j ACCEPT
  #Запретить исходящий 25 порт
  ${IPT} -I OUTPUT -p tcp -m tcp --sport 25 -j DROP
  ${IPT} -I OUTPUT -p tcp -m tcp --dport 25 -j DROP
  # Доступ к странице авторизации
  ${IPT} -A INPUT -p TCP -s 0/0  --sport 80 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 80 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --sport 81 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 81 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --sport 443 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 443 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --sport 9443 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 9443 -j ACCEPT
  ${IPT} -I INPUT -p udp -m udp --dport 161 -j ACCEPT
  ${IPT} -I INPUT -p udp -m udp --dport 162 -j ACCEPT
  # MYSQL
  ${IPT} -A INPUT -p TCP -s 0/0  --sport 3306 -j ACCEPT
  ${IPT} -A INPUT -p TCP -s 0/0  --dport 3306 -j ACCEPT

  ${IPT} -A FORWARD -p tcp -m tcp -s 0/0 --dport 80 -j ACCEPT
  ${IPT} -A FORWARD -p tcp -m tcp -s 0/0 --dport 443 -j ACCEPT
  ${IPT} -A FORWARD -p tcp -m tcp -s 0/0 --dport 9443 -j ACCEPT

  if [ "$IPSET" = "" ]; then
    echo "Error: ipset not install";
    return 0;
  fi;

  # UNKNOWN CLIENT
  unknown_clients=`${IPSET} -L |grep unknown_clients|sed 's/ //'|awk -F: '{ print $2 }'`
  if [ "${unknown_clients}" = "" ]; then
    echo "ADD unknown_clients"
    ${IPSET} -N unknown_clients iphash
  fi;

  # SET
  allownet=`${IPSET} -L |grep allownet|sed 's/ //'|awk -F: '{ print $2 }'`
  if [ "${allownet}" = "" ]; then
    echo "ADD allownet"
    ${IPSET} -N allownet nethash
  fi;

# USERS
  allowip=`${IPSET} -L |grep allowip|sed 's/ //'|awk -F: '{ print $2 }'`
  if [ "${allowip}" = "" ]; then
    echo "ADD IPSET: allowip"
    ${IPSET} -N allowip iphash
  fi;

  ${IPT} -t nat -A PREROUTING -m set --match-set unknown_clients src -p tcp --dport 80 -j REDIRECT --to-ports 81
  ${IPT} -t nat -A PREROUTING -m set --match-set unknown_clients src -p tcp --dport 443 -j REDIRECT --to-ports 81
  ${IPT} -t nat -A PREROUTING -m set --match-set unknown_clients src -p tcp --dport 9443 -j REDIRECT --to-ports 81

  ${IPT} -A FORWARD -m set --match-set allownet src -j ACCEPT
  ${IPT} -A FORWARD -m set --match-set allownet dst -j ACCEPT
  ${IPT} -t nat -A PREROUTING -m set --match-set allownet src -j ACCEPT

  ${IPT} -A FORWARD -m set --match-set allowip src -j ACCEPT
  ${IPT} -A FORWARD -m set --match-set allowip dst -j ACCEPT
  ${IPT} -t nat -A PREROUTING -m set --match-set allowip src -j ACCEPT

  if [ "${abills_allow_dhcp_port_67}" != "" ]; then
    # Перенаправление IPN клиентов
    ALLOW_DHCP=`echo ${abills_allow_dhcp_port_67}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
    echo "ALLOW DHCP: ${ALLOW_DHCP}"
    for DHCP_POOL in ${ALLOW_DHCP}; do
      ${IPT} -I INPUT -p UDP -s ${DHCP_POOL}  --sport 67 -j ACCEPT
      ${IPT} -I INPUT -p UDP -s ${DHCP_POOL}  --dport 67 -j ACCEPT
      echo "Allow ${DHCP_POOL} to port 67"
    done
  else
    echo "unknown DHCP pool"
  fi;

  if [ "${abills_redirect_clients_pool}" != "" ]; then
    # Перенаправление IPN клиентов
    REDIRECT_POOL=`echo ${abills_redirect_clients_pool}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
    echo "REDIRECT_POOL: ${REDIRECT_POOL}"
    for REDIRECT_IPN_POOL in ${REDIRECT_POOL}; do
      ${IPT} -t nat -A PREROUTING -s ${REDIRECT_IPN_POOL} -p tcp --dport 80 -j REDIRECT --to-ports 80
      ${IPT} -t nat -A PREROUTING -s ${REDIRECT_IPN_POOL} -p tcp --dport 443 -j REDIRECT --to-ports 80
      ${IPT} -t nat -A PREROUTING -s ${REDIRECT_IPN_POOL} -p tcp --dport 9443 -j REDIRECT --to-ports 80
      echo "Redirect UP ${REDIRECT_IPN_POOL}"
    done
  else
    echo "unknown ABillS IPN IFACES"
  fi;

  if [ "${abills_ipn_allow_ip}" != "" ]; then
    ABILLS_ALLOW_IP=`echo ${abills_ipn_allow_ip}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
    echo "Enable allow ips ${ABILLS_ALLOW_IP}";

    for IP in ${ABILLS_ALLOW_IP} ; do
      ${IPT} -I FORWARD  -d ${IP} -j ACCEPT;
      ${IPT} -I FORWARD  -s ${IP} -j ACCEPT;
#        if [ x"${abills_nat}" != x ]; then
      ${IPT} -t nat -I PREROUTING -d ${IP} -j ACCEPT;
      ${IPT} -t nat -I PREROUTING -s ${IP} -j ACCEPT;
#        fi;
    done;
  else
    echo "unknown ABillS IPN ALLOW IP"
  fi;
elif [ "${ACTION}" = stop ]; then
  echo "ACTION: ${ACTION}";
  # Разрешаем всё и всем
  ${IPT} -P INPUT ACCEPT
  ${IPT} -P OUTPUT ACCEPT
  ${IPT} -P FORWARD ACCEPT

  # Чистим все правила
  ${IPT} -F
  ${IPT} -F -t nat
  ${IPT} -F -t mangle
  ${IPT} -X
  ${IPT} -X -t nat
  ${IPT} -X -t mangle

  unknown_clients=`${IPSET} -L |grep unknown_clients|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ "${unknown_clients}" != "" ]; then
      echo "DELETE unknown_clients"
      ${IPSET} destroy unknown_clients
    fi;
  allowip=`${IPSET} -L |grep allowip|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ "${allowip}" != "" ]; then
      echo "DELETE allowip"
      ${IPSET} destroy allowip
    fi;
  allownet=`${IPSET} -L |grep allownet|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ "${allownet}" != "" ]; then
      echo "DELETE allownet"
      ${IPSET} destroy allownet
    fi;

elif [ "${ACTION}" = "status" ]; then
  ${IPT} -S
fi;

}


#**********************************************************
# Abills Shapper
#**********************************************************
abills_shaper() {

  if [ "${abills_shaper_enable}" = NO ]; then
    return 0;
  elif [ "${abills_shaper_enable}" = NAT ]; then
    return 0;
  elif [ "${abills_shaper_enable}" = "" ]; then
    return 0;
  fi;

  echo "ABillS Shapper ${ACTION}"

  if [ "${ACTION}" = start ]; then
    for INTERFACE in ${IPN_INTERFACES}; do
      TCQA="${TC} qdisc add dev ${INTERFACE}"
      TCQD="${TC} qdisc del dev ${INTERFACE}"

      ${TCQD} root &>/dev/null
      ${TCQD} ingress &>/dev/null

      ${TCQA} root handle 1: htb
      ${TCQA} handle ffff: ingress

      echo "Shaper UP ${INTERFACE}"
    
      ${IPT} -A FORWARD -j DROP -i ${INTERFACE}
    done
  elif [ x${ACTION} = xstop ]; then
    for INTERFACE in ${IPN_INTERFACES}; do
      TCQA="${TC} qdisc add dev ${INTERFACE}"
      TCQD="${TC} qdisc del dev ${INTERFACE}"

      ${TCQD} root &>/dev/null
      ${TCQD} ingress &>/dev/null

      echo "Shaper DOWN ${INTERFACE}"
    done
  elif [ x${ACTION} = xstatus ]; then
    for INTERFACE in ${IPN_INTERFACES}; do
      echo "Internal: ${INTERFACE}"
      ${TC} class show dev ${INTERFACE}
      ${TC} qdisc show dev ${INTERFACE}
    done
  fi;

}

#**********************************************************
# Abills Shapper
# With mangle support
#**********************************************************
abills_shaper2() { 

  if [ "${abills_shaper2_enable}" = NO ]; then
    return 0;
  fi;

  echo "ABillS Shapper 2 ${ACTION}"

  SPEEDUP=1000mbit
  SPEEDDOWN=1000mbit

  if [ "${ACTION}" = "start" ]; then
    ${IPT} -t mangle --flush
    ${TC} qdisc add dev ${EXTERNAL_INTERFACE} root handle 1: htb
    ${TC} class add dev ${EXTERNAL_INTERFACE} parent 1: classid 1:1 htb rate ${SPEEDDOWN} ceil ${SPEEDDOWN}

    for INTERFACE in ${IPN_INTERFACES}; do
      ${TC} qdisc add dev ${INTERFACE} root handle 1: htb
      ${TC} class add dev ${INTERFACE} parent 1: classid 1:1 htb rate ${SPEEDUP} ceil ${SPEEDUP}

#    ${IPT} -A FORWARD -j DROP -i ${INTERFACE}
      echo "Shaper UP ${INTERFACE}"
    done
  elif [ "${ACTION}" = "stop" ]; then
    ${IPT} -t mangle --flush
    EI=`tc qdisc show dev ${EXTERNAL_INTERFACE} |grep htb | sed 's/ //g'`
    if [ "${EI}" != "" ]; then
      ${TC} qdisc del dev ${EXTERNAL_INTERFACE} root handle 1: htb
    fi;
    for INTERFACE in ${IPN_INTERFACES}; do
      II=`tc qdisc show dev ${INTERFACE} |grep htb | sed 's/ //g'`
      if [ "${II}" != "" ]; then
        ${TC} qdisc del dev ${INTERFACE} root handle 1: htb
        echo "Shaper DOWN ${INTERFACE}"
      fi;
    done
  elif [ "${ACTION}" = "status" ]; then
    echo "External: ${EXTERNAL_INTERFACE}";
    ${TC} class show dev ${EXTERNAL_INTERFACE}
    for INTERFACE in ${IPN_INTERFACES}; do
      echo "Internal: ${INTERFACE}"
      ${TC} class show dev ${INTERFACE}
    done
  fi;

}

#**********************************************************
# Abills Shapper
# With IPMARK support
#**********************************************************
abills_shaper3() {

  if [ x${abills_shaper3_enable} = xNO ]; then
    return 0;
  elif [ x${abills_shaper3_enable} = x ]; then
    return 0;
  fi;
echo "ABillS Shapper 3 ${ACTION}"
if [ "${ACTION}" = start ]; then
  ${IPT} -t mangle -A POSTROUTING -o ${EXTERNAL_INTERFACE} -j IPMARK --addr src --and-mask 0xffff --or-mask 0x10000
  ${TC} qdisc add dev ${EXTERNAL_INTERFACE} root handle 1: htb
  ${TC} filter add dev ${EXTERNAL_INTERFACE} parent 1:0 protocol ip fw
  echo "Shaper 3 UP ${EXTERNAL_INTERFACE}"
  for INTERFACE in ${IPN_INTERFACES}; do
    ${IPT} -t mangle -A POSTROUTING -o ${INTERFACE} -j IPMARK --addr dst --and-mask 0xffff --or-mask 0x10000
    ${TC} qdisc add dev ${INTERFACE} root handle 1: htb
    ${TC} filter add dev ${INTERFACE} parent 1:0 protocol ip fw

    echo "Shaper 3 UP ${INTERFACE}"
  done
elif [ "${ACTION}" = stop ]; then
  ${IPT} -t mangle --flush
  EI=`tc qdisc show dev ${EXTERNAL_INTERFACE} |grep htb | sed 's/ //g'`
  if [ "${EI}" != "" ]; then
    ${TC} qdisc del dev ${EXTERNAL_INTERFACE} root
  fi;
  for INTERFACE in ${IPN_INTERFACES}; do
    II=`tc qdisc show dev ${INTERFACE} |grep htb | sed 's/ //g'`
  if [ "${II}" != "" ]; then
    ${TC} qdisc del dev ${INTERFACE} root
    echo "Shaper DOWN ${INTERFACE}"
  fi;
  done
elif [ "${ACTION}" = status ]; then
  echo "External: ${EXTERNAL_INTERFACE}";
  ${TC} class show dev ${EXTERNAL_INTERFACE}
  for INTERFACE in ${IPN_INTERFACES}; do
    echo "Internal: ${INTERFACE}"
    ${TC} class show dev ${INTERFACE}
  done
fi;

}

#**********************************************************
#Ipn Sections
# Enable IPN
#**********************************************************
abills_ipn() {

  if [ x${abills_ipn_nas_id} = x ]; then
    return 0;
  fi;

  if [ x${ACTION} = xstart ]; then
    echo "Enable users IPN"
    ${IPT} -P FORWARD DROP
    ${BILLING_DIR}/libexec/periodic monthly MODULES=Ipn SRESTART=1 NO_ADM_REPORT=1 NO_RULE NAS_IDS="${abills_ipn_nas_id}"
  fi;

}

#**********************************************************
#NAT Section
#**********************************************************
abills_nat() {

  if [ "${abills_nat}" = "" ]; then
    return 0;
  fi;

  echo "ABillS NAT ${ACTION}"

  if [ x${ACTION} = xstatus ]; then
    ${IPT} -t nat -L
    return 0;
  fi;

  ABILLS_IPS=`echo ${abills_nat}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
#  echo "${ABILLS_IPS}";

  for ABILLS_IPS_NAT in ${ABILLS_IPS}; do
    # NAT External IP
    NAT_IPS=`echo ${ABILLS_IPS_NAT} | awk -F: '{ print $1 }'`;
    # Fake net
    FAKE_NET=`echo ${ABILLS_IPS_NAT} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
    #NAT IF
    NAT_IF=`echo ${ABILLS_IPS_NAT} | awk -F: '{ print $3 }'`;
    echo  "NAT: $NAT_IPS | $FAKE_NET $NAT_IF"
    if [ x${NAT_IPS} = x ]; then
      NAT_IPS=all
    fi;
    # nat configuration

    for IP in ${NAT_IPS}; do
      if [ w"${ACTION}" = wstart ]; then 
        for IP_NAT in ${FAKE_NET}; do
          ${IPT} -t nat -A POSTROUTING -s ${IP_NAT} -j SNAT --to-source ${IP}
          echo "Enable NAT for ${IP_NAT} -> ${IP}"
        done;
      fi;
    done;
  done;

  if [ x${ACTION} = xstop ]; then
    ${IPT} -F -t nat
    ${IPT} -X -t nat
    echo "Disable NAT"
  fi;

}


#**********************************************************
#Neg deposit FWD Section
#**********************************************************
neg_deposit() {
  
  if [ "${abills_neg_deposit}" = "" ]; then
    return 0;
  fi;

  echo "NEG_DEPOSIT"

  if [ "${abills_neg_deposit}" = "YES" ]; then
    USER_NET="0.0.0.0/0"
  else
    # Portal IP
    PORTAL_IP=`echo ${abills_neg_deposit} | awk -F: '{ print $1 }'`;
    # Fake net
    USER_NET=`echo ${abills_neg_deposit} | awk -F: '{ print $2 }' | sed 's/,/ /g'`;
    # Users IF
    USER_IF=`echo ${abills_neg_deposit} | awk -F: '{ print $3 }'`;
    echo  "$PORTAL_IP $USER_NET $USER_IF"
  fi;


  for IP in ${USER_NET}; do  
    ${IPT} -t nat -A PREROUTING -s ${IP} -p tcp --dport 80 -j REDIRECT --to-ports 80 -i ${USER_IF}
  done;
  
}


#**********************************************************
#
#**********************************************************
abills_dhcp_shaper() {
  if [ x${abills_dhcp_shaper} = xNO ]; then
    return 0;
  elif [ x${abills_dhcp_shaper} = x ]; then
    return 0;
  fi;

  if [ -f ${BILLING_DIR}/libexec/ipoe_shapper.pl ]; then
    if [ w${ACTION} = wstart ]; then
      ${BILLING_DIR}/libexec/ipoe_shapper.pl -d ${NAS_IDS} IPN_SHAPPER
      echo " ${BILLING_DIR}/libexec/ipoe_shapper.pl -d ${NAS_IDS} IPN_SHAPPER";
    elif [ w${ACTION} = wstop ]; then
      if [ -f ${BILLING_DIR}/var/log/ipoe_shapper.pid ]; then
        IPOE_PID=`cat ${BILLING_DIR}/var/log/ipoe_shapper.pid`
        if  ps ax | grep -v grep | grep ipoe_shapper > /dev/null ; then
          echo "kill -9 ${IPOE_PID}"
          kill -9 ${IPOE_PID} ;
        fi;
        rm ${BILLING_DIR}/var/log/ipoe_shapper.pid
      else
        echo "Can\'t find 'ipoe_shapper.pid' "
      fi;
    fi;
  else
    echo "Can\'t find 'ipoe_shapper.pl' "
  fi;
}
#**********************************************************
#
#**********************************************************
check_server(){
  if [ x${abills_mysql_server_status} = xNO ]; then
    return 0;
  elif [ x${abills_mysql_server_status} = x ]; then
    return 0;
  fi;

  if [ "${ACTION}" = "start" ]; then
    while : ; do
      if ping -c5 -l5 -W2 ${abills_mysql_server} 2>&1 | grep "64 bytes from" > /dev/null ; then
        echo "Abills Mysql server is UP!!!" ;
        sleep 5;
        return 0;
      else
        echo "Abills Mysql server is DOWN!!!" ;
      fi;
      sleep 5
    done
  fi;

}

#**********************************************************
#IRQ2SMP
#**********************************************************
irq2smp(){
  if [ x${abills_irq2smp} = xNO ]; then
    return 0;
  elif [ x${abills_irq2smp} = x ]; then
    return 0;
  fi;

if [ w${ACTION} = wstart ]; then
  ncpus=`grep -ciw ^processor /proc/cpuinfo`
  test "$ncpus" -gt 1 || exit 1

  n=0
  for irq in `cat /proc/interrupts | grep eth[0-9]- | awk '{print $1}' | sed s/\://g`; do
    f="/proc/irq/$irq/smp_affinity"
    test -r "$f" || continue
    cpu=$[$ncpus - ($n % $ncpus) - 1]
    if [ ${cpu} -ge 0 ]; then
      mask=`printf %x $[2 ** $cpu]`
      echo "Assign SMP affinity: eth$n, irq $irq, cpu $cpu, mask 0x$mask"
      echo "$mask" > "$f"
      let n+=1
    fi
  done;
fi;
}
#**********************************************************
#IP Unnumbered
#**********************************************************
ip_unnumbered(){
  
  if [ x${abills_unnumbered} = xNO ]; then
    return 0;
  elif [ x${abills_unnumbered} = x ]; then
    return 0;
  fi;

if [ w${ACTION} = wstart ]; then

  if [ x"${abills_unnumbered_net}" != x ]; then
      UNNUNBERED_NETS=`echo ${abills_unnumbered_net}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
      for UNNUNBERED_NET in ${UNNUNBERED_NETS}; do
         /sbin/ip ro replace unreachable ${UNNUNBERED_NET}
         echo "Add route unreachable ${UNNUNBERED_NET}"
      done
      if [ x"${abills_unnumbered_iface}" != x ]; then
        UNNUNBERED_INTERFACES="";
        unnumbered_ifaces=`echo ${abills_unnumbered_iface} | sed 'N;s/\n/ /' |sed 's/,/ /g'`
        for i in ${unnumbered_ifaces}; do
          if [[ ${i} =~ - ]]; then
             vlan_name=`echo ${i}|sed 's/vlan//'`
             IFS='-' read -a start_stop <<< "${vlan_name}"
             for cur_iface in `seq ${start_stop[0]} ${start_stop[1]}`;
             do
                  UNNUNBERED_INTERFACES="$UNNUNBERED_INTERFACES vlan${cur_iface}"
             done
          else
              UNNUNBERED_INTERFACES="$UNNUNBERED_INTERFACES $i"
          fi;
        done
        if [ x"${abills_unnumbered_gw}" != x ]; then
          UNNUNBERED_GW=`echo ${abills_unnumbered_gw}  |sed 'N;s/\n/ /' |sed 's/;/ /g'`;
          for UNNUNBERED_INTERFACE in ${UNNUNBERED_INTERFACES}; do
               for GW in ${UNNUNBERED_GW}; do
              /sbin/ip addr add ${GW} dev ${UNNUNBERED_INTERFACE}
              echo "Add  $GW dev ${UNNUNBERED_INTERFACE}"
              done
          done
        else
          echo "unknown IP Unnumbered GATEWAY"
        fi;

      else
        echo "unknown IP Unnumbered IFACE"
      fi;

  else
   echo "unknown IP Unnumbered NET"
  fi;

fi;
if [ w${ACTION} = wstop ]; then
  /sbin/ip route flush type  unreachable
  DEVACES_ADDR=`/sbin/ip addr show  |grep /32 |  ip addr show  |grep /32 |awk '/inet/{print $2,$5}'|sed 's/ /:/g' |sed 'N;s/\n/ /'`
  for DEV_ADDR in ${DEVACES_ADDR}; do
    IP=`echo ${DEV_ADDR} |awk -F: '{print $1}'`
    DEV=`echo ${DEV_ADDR} |awk -F: '{print $2}'`
    /sbin/ip addr del ${IP} dev ${DEV}
#    /sbin/ip route flush dev ${DEV}
    echo "DELETE ${IP} for dev ${DEV}"
  done
fi;

}


#**********************************************************
#Netblock
#
#  Active netblock
#
#
#
#  Block rule 113
#
#**********************************************************
netblock_active() {

  #Netblock Section
  if [ "${abills_netblock}" = "NO" ]; then
    return 0;
  fi;

  NETBLOCK_REDIRECT_IP=${abills_netblock_redirect_ip};
  NETBLOCK_REDIRECT_PORT=82;
  NETBLOCK_IF=${EXTERNAL_INTERFACE};
  NETBLOCK_LIST=netblock

  if [ "${IPSET}" = "" ]; then
    echo "Error: ipset not install";
    return 0;
  fi;

  # NETBLOCK list

  if [ "${ACTION}" = "show" ]; then
    ${IPSET} list ${NETBLOCK_LIST}
  elif [ "${ACTION}" = "stop" ]; then
    echo "${NETBLOCK_LIST} Destroy"
    ${IPSET} destroy ${NETBLOCK_LIST}
  else
    unknown_clients=`${IPSET} -L |grep ${NETBLOCK_LIST}|sed 's/ //'|awk -F: '{ print $2 }'`
    if [ "${NETBLOCK_LIST}" = "" ]; then
      echo "${NETBLOCK_LIST}"
      ${IPSET} -N ${NETBLOCK_LIST} iphash
    fi;

    #Drop section
    ${IPT} -A INPUT -m set --set ${NETBLOCK_LIST} dst -j DROP
    #Redirect section
#    if [ "${abills_netblock_type}" != "" -a -f /usr/abills/libexec/billd ]; then
#      NETBLOCK_CMD="/usr/abills/libexec/billd netblock ${abills_netblock_type}"
#      ${NETBLOCK_CMD}
#    fi;
#    if [ "${NETBLOCK_REDIRECT_IP}" != "" ]; then
#      ${IPFW} add 115 fwd 127.0.0.1,${NETBLOCK_REDIRECT_PORT} tcp from any to "table(13)"  dst-port 80,443 via ${NETBLOCK_IF}
#    fi;
#
#    ${IPFW} add 116 deny all from any to "table(13)" via ${NETBLOCK_IF}
  fi;

}


#############################Скрипт################################
case "$1" in start) echo -n "START : $name"
      echo ""
      all_rulles start
      echo "."
      ;; 
  stop) echo -n "STOP : $name"
      echo ""
      all_rulles stop
      echo "."
      ;; 
  restart) echo -n "RESTART : $name"
      echo ""
      all_rulles stop
      all_rulles start
      echo "."
      ;;
  status) echo -n "STATUS : $name"
      echo ""
      all_rulles status
      echo "."
      ;;
    *) echo "Usage: /etc/init.d/shapper_start.sh
 start|stop|status|restart|clear"
    exit 1
    ;; 
    esac 


exit 0
