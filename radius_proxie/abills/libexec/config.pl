#!/usr/bin/perl -w
# Abills configuretion file

$PROGRAM='~AsmodeuS~ Billing System';

#DB configuration

#DB configuration
$conf{dbhost}='localhost';
$conf{dbname}='abills';
$conf{dbuser}='abills';
$conf{dbpasswd}='kjdgf643ashd';
$conf{dbtype}='mysql';
#For MySQL 5 and highter (cp1251, utf8)

$conf{dbcharset}='utf8';
$conf{MAIL_CHARSET}='utf-8';
$conf{default_charset}='utf-8';

$conf{mpd_filters}=1;

#Mail configuration
$conf{ADMIN_MAIL}='admin@intelekt.cv.ua';
$conf{USERS_MAIL_DOMAIN}='intelekt.cv.ua';
$conf{default_language}='ukraine';
$conf{WEB_TITLE}='Intelekt ISP Billing';
#$conf{START_PERIOD_DAY}=5;
$conf{RADIUS2}=1;


@MODULES = ('Internet',
            'Abon',
            'Docs',
#            'Dhcphosts',
#            'Vlan',  
#            'Dunes',
#            'Mdelivery',
            'Msgs',
            'Paysys', 
            'Sqlcmd');

$conf{DOCS_VAT_INCLUDE}=0; 
$conf{MONEY_UNIT_NAMES}=['грн.','коп.'];

@EX_PAYMENT_METHODS = ('Підключення(Г)','Підключення(Б)','Послуга(Г)','Послуга(Б)','Товар(Г)','Товар(Б)');

#$conf{MSGS_REDIRECT_FILTER_ADD}='EXEC:/usr/bin/ssh -o StrictHostKeyChecking=no -i /usr/abills/Certs/id_dsa.abills_admin -q abills_admin@194.8.147.178  "/home/intelekt/abills/misc/msgs_filter.sh %ACTION% %UIDS%";RAD:mpd-table-static+=100=%IP%';
$conf{MSGS_REDIRECT_FILTER_ADD}='EXEC:/usr/bin/ssh -o StrictHostKeyChecking=no -i /usr/abills/Certs/id_dsa.abills_admin -q abills_admin@194.8.147.178  "/usr/local/bin/sudo /usr/abills/misc/msgs_filter.sh %ACTION% %UIDS%";RAD:mpd-table-static+=100=%IP%';

$conf{MSGS_REDIRECT_FILTER_DEL}='EXEC:/usr/bin/ssh -o StrictHostKeyChecking=no -i /usr/abills/Certs/id_dsa.abills_admin -q abills_admin@194.8.147.178  "/usr/local/bin/sudo /usr/abills/misc/msgs_filter.sh %IP% >> /tmp/msg"; /usr/bin/ssh -o StrictHostKeyChecking=no -i /usr/abills/Certs/id_dsa.abills_admin -q abills_admin@194.8.147.179  "/usr/local/bin/sudo /usr/abills/misc/msgs_filter.sh %IP% >> /tmp/msg"; /usr/bin/ssh -o StrictHostKeyChecking=no -i /usr/abills/Certs/id_dsa.abills_admin -q abills_admin@194.8.147.180  "/usr/local/bin/sudo /usr/abills/misc/msgs_filter.sh %IP% >> /tmp/msg"; echo "%DATE% %MSG_ID% %LOGIN%-%IP%-" >> /tmp/111';

#$conf{MSGS_UNREAD_FORWARD}='0:0:http://intelekt.cv.ua/index.php?option=com_content&task=view&id=28&GID=%GID%&MESSAGE_CHAPTER=%MESSAGE_CHAPTER%;';
$conf{MSGS_UNREAD_FORWARD}='0:0:http://194.8.144.1/msg_show.cgi';


$conf{DOCS_PDF_PRINT}=1; 

%ACCT = ();
#For VoIP GNU Gatekeeper accounting
$ACCT{gnugk} = 'Voip_aaa';

%AUTH = ();
#For VoIP GNU Gatekeeper Auth
$AUTH{gnugk} = 'Voip_aaa';
#$AUTH{mx80} = 'Mx80';
#$ACCT{mx80} = 'Mx80';

$AUTH{mpd5}='Auth2';
$ACCT{mpd5}='Acct2';
$AUTH{mx80} = 'Mx802';
$ACCT{mx80} = 'Mx802';



$conf{SHARING_APACHE_ERROR_LOG}='ssh  -o StrictHostKeyChecking=no '.
   ' -i /usr/abills/Certs/id_dsa.files files@remote.host '.
   ' "cat /var/log/httpd/error.log" |';
$conf{SHARING_USER_CHG_TP}=1;

#Technical works
#$conf{tech_works}='Technical works';

#Periodic functions
$conf{p_admin_mails}=1;  # Send periodic admin reports
$conf{p_users_mails}=1;  # Send user warning  messages

$conf{user_finance_menu}=1;


$conf{external_payments}='/usr/abills/misc/autozh.pl HANGUP';
$conf{external_userchange}='/usr/abills/misc/autozh.pl HANGUP';

# chap encryption decription key
$conf{secretkey}="test12345678901234567890";
#$conf{s_detalization}=1; #make session detalization recomended for vpn leathed lines
$conf{ERROR2DB}=1;
$conf{periodic_check}=1;

#Octets direction
# server - Count octets from server side
# user   - Count octets from user side (default)
$conf{octets_direction}='user';

#Check web interface brute force
$conf{wi_bruteforce}=10;

#Minimum session costs
$conf{MINIMUM_SESSION_TIME}=10; # minimum session time for push session to db
$conf{MINIMUM_SESSION_TRAF}=200; # minimum session trafic for push session to db
$conf{MIN_USE_FEES_CONSIDE}=4;
#System admin id
#ID for system operation, periodic procces
$conf{SYSTEM_ADMIN_ID}=1;

#System Langs
$conf{LANGS}="english:English;
 russian:Русский;
 ukraine:Українська;
 bulgarian:Болгарска;
 french:French";

#Web interface
$conf{PASSWD_LENGTH}=6;
$conf{MAX_USERNAME_LENGTH}=15;
# User name expration
$conf{USERNAMEREGEXP}="^[A-Za-z0-9_][A-za-z0-9_-]*\$";
$conf{list_max_recs}=25;
$conf{web_session_timeout} = 1800;
$conf{user_chg_passwd}='no';
#Max session traffic Mb
$conf{MAX_SESSION_TRAFFIC} = 2047; 

# DV options
$conf{DV_MIN_USER_FULLPERIOD}=1;
$conf{DV_USER_CHG_TP}=1;
$conf{EXT_BILL_ACCOUNT}=1;
$conf{DV_USER_CHG_TP_SHEDULE}=1;
$conf{DV_USER_CHG_TP_NPERIOD}=1;
$conf{DV_LOG_CLEAN_PERIOD}=90;
#$conf{ERROR_ALIVE_COUNT}=9;
$conf{PASSWORDLESS_ACCESS}=1;

$conf{MAC_AUTO_ASSIGN}=1;
$conf{KBYTE_SIZE} = 1024;
# Check script rannig time
$conf{time_check}=1;

# Debug mod 
$conf{debug}=10;
$conf{foreground}=0;
$conf{debugmods}='LOG_ALERT LOG_WARNING LOG_ERR LOG_INFO';
#show auth and accounting time need Time::HiRes module (available from CPAN)
# Log levels. For details see <syslog.h>
%log_levels = ('LOG_EMERG' => 0,
'LOG_ALERT'   => 1,
'LOG_CRIT'    => 2,
'LOG_ERR'     => 3,
'LOG_WARNING' => 4,
'LOG_NOTICE'  => 5,
'LOG_INFO'    => 6,
'LOG_DEBUG'   => 7,
'LOG_SQL'     => 8);

#Check password from radius or FTP servers for web interface
#Radius
#$conf{check_access} = { NAS_IP        => '192.168.101.17:1812',
#                        NAS_FRAMED_IP => '192.168.101.17',
#                        NAS_SECRET    => 'test'
#                       };
# FTP
#  $conf{check_access} = { NAS_IP      => '192.168.101.17:21'
#                         };

#Firewall start rule numbers
# (GLobal, Class 1, Class 2)
@START_FW = (3000, 2000, 1000);


# Backup SQL data
$conf{BACKUP_DIR}='/usr/abills/backup';


# Folders and files
$base_dir='/usr/abills/';
$lang_path=$base_dir . 'language/';
$lib_path=$base_dir .'libexec/';
$var_dir=$base_dir .'var/';
$conf{SPOOL_DIR}=$base_dir.'var/q';

# Template folder
$conf{TPL_DIR}   = $base_dir . 'Abills/templates/';
$conf{LOG_DEBUG} = $base_dir . 'var/log/abills.debug';
$conf{WEB_LOGFILE} = $base_dir . 'var/log/weblog.log';
$conf{LOGFILE}   = $base_dir . 'var/log/abills.log';
$conf{LOG_ACCT}  = $base_dir . 'var/log/acct.log';


#For file auth type allow file
$conf{extern_acct_dir}=$base_dir.'libexec/ext_acct/';

$conf{MAILBOX_PATH}='/var/mail/';
# Low bounds

use POSIX qw(strftime);
$DATE = strftime "%Y-%m-%d", localtime(time);

$TIME = strftime "%H:%M:%S", localtime(time);
$curtime = strftime("%F %H.%M.%S", localtime(time));
$year = strftime("%Y", localtime(time));


#24nonStop
$conf{PAYSYS_24_NON_STOP_SECRET}='gh749dytws';
$conf{PAYSYS_24_NON_SERVICE_ID}=1;
$conf{PAYSYS_24_NON_STOP_ACCOUNT_KEY}='LOGIN';
$conf{PAYSYS_24_NON_STOP_MIN_AMOUNT}=5;

#KnopkaKredyt
$conf{user_credit_change}='1001:5:0:1';

#EasySoft
#$conf{PAYSYS_EASYPAY_TOKEN}='';
$conf{PAYSYS_EASYPAY_SERVICE_ID}='819';
$conf{PAYSYS_EASYPAY_ACCOUNT_KEY}='LOGIN';
#$conf{PAYSYS_24_NON_STOP_MIN_AMOUNT}=5;


#Paymaster
$conf{PAYSYS_PAYMASTER_MERCHANT_ID}='1070';
$conf{PAYSYS_PAYMASTER_SECRET}='1151400';
$conf{PAYSYS_PAYMASTER_TESTMODE}='1:0';


$conf{PAYSYS_SUCCESSIONS}='213.186.115.164,213.186.115.168,213.186.115.170:99:TYME:TYME:osmp_payments';
$conf{PAYSYS_OSMP_ACCOUNT_KEY}='LOGIN';
$conf{PAYSYS_OSMP_EXT_PARAMS}='deposit,fio,contract_id,address_full';

#MX80-PPPoE
# MX80_IPOE_PROFILES
$conf{MX80_PROFILES}='
WRONG_PASS:svc1-guest-pppoe(svc-filter-in-wrongpassword);
NEG_DEPOSIT:svc-guest-pppoe(svc-filter-in-nomoney);
AUTH_ERROR:svc1-guest-pppoe(svc-filter-in-unknownerror);
NOT_ALLOW_SERVICE:svc1-guest-pppoe(svc-filter-in-notallowservice);
DISABLE:svc1-guest-pppoe(svc-filter-in-disable);
WRONG_PORT:svc1-guest-pppoe(svc-filter-in-wrongport);
WRONG_CID:svc1-guest-pppoe(svc-filter-in-wrongcid);
';

#$conf{MX80_IPOE_PROFILES}='
#WRONG_PASS:svc-guest-pppoe(svc-filter-in-wrongpassword);
#NEG_DEPOSIT:svc-guest-pppoe(svc-filter-in-nomoney);
#AUTH_ERROR:svc-guest-pppoe(svc-filter-in-unknownerror);
#NOT_ALLOW_SERVICE:svc-guest-pppoe(svc-filter-in-notallowservice);
#DISABLE:svc-guest-pppoe(svc-filter-in-disable);
#WRONG_PORT:svc-guest-pppoe(svc-filter-in-wrongport);
#WRONG_CID:svc-guest-pppoe(svc-filter-in-wrongcid);
#';

$conf{MX80_DEBUG}=1;

