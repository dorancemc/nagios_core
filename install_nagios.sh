#!/bin/bash
#
# Copyright (C) 2016 - DMC Ingenieria SAS. http://dmci.co
# Author: Dorance Martinez C dorancemc@gmail.com
# SPDX-License-Identifier: GPL-3.0+
#
# Descripcion: Script para installar nagios core
# Version: 0.6.0 - 16-mar-2020
# Validado: Debian >=9
#

nagioscore_version="4.4.5"
pnp4nagios_version="0.6.26"

temp_path="/temp/nagios_`date +%Y%m%d%H%M%S`"
install_path="/opt/nagios"
install_pnp4nagios="/opt/pnp4nagios"
install_nagiosql="/opt/nagiosql"

user_nagios="nagios"

mysql_root_passwd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
nagiosadmin_passwd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
mynagiosql_db="nagiosqldb"
mynagiosql_user="nagiosqluser"
mynagiosql_passwd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
mynagiosql_host="localhost"

hostname="nagioscore"

linux_variant() {
  if [ -f "/etc/debian_version" ]; then
    if ! command_exists lsb_release ; then
      apt-get install -y lsb-release
    fi
    distro=$(lsb_release -s -i | tr '[:upper:]' '[:lower:]')
    flavour=$(lsb_release -s -c )
    version=$(lsb_release -s -r | cut -d. -f1 )
  else
    distro="unknown"
  fi
}

command_exists() {
    type "$1" &> /dev/null ;
}

user_exist() {
  if id "$1" >/dev/null 2>&1; then
    echo "user $1 exists"
  else
    groupadd $1 && useradd -m -d $2 -g $1 -s /bin/bash $1 &&
    su - $1 -c "ssh-keygen -f $2/.ssh/id_rsa -t rsa -N ''"
  fi
}

file_exist() {
  if [ -f $1 ]; then
    cp ${1} ${1}-backup_`date +%Y%m%d%H%M%S`
  fi
}

insertAfter() {
 local file="$1" line="$2" newText="$3"
 sed -i -e "/^$line$/a"$'\\\n'"$newText"$'\n' "$file"
}

raspbian() {
  if [ $version -ge 9 ]; then
    INIT_TYPE="systemd"
  else
    echo "This script requires Raspian 9"
    exit 1
  fi
  debian_flavor &&
  return 0
}

debian() {
  if [ $version -ge 9 ]; then
    INIT_TYPE="systemd"
  else
    echo "This script requires Debian 9 'stretch'"
    exit 1
  fi
  debian_flavor &&
  return 0
}

ubuntu() {
  if [ $version -ge 16 ]; then
    INIT_TYPE="systemd"
  else
    INIT_TYPE="sysv"
  fi
  debian_flavor &&
  return 0
}

debian_flavor() {
  user_apache="www-data"
  debian_pkgs &&
  install_mariadb &&
  install_nagioscore &&
  configure_nagioscore &&
  install_nrpe &&
  configure_nrpe &&
  install_pnp4nagios &&
  configure_pnp4nagios &&
  install_grafana &&
  install_nagiosql &&
  configure_nagiosql &&
  crear_backup &&
  crear_carcelero &&
  return 0
}

rh() {
  if [ $version -ge 7 ]; then
    INIT_TYPE="systemd"
  else
    INIT_TYPE="sysv"
  fi
  return 0
}

rh_packages() {
  yum update -y
  yum install -y wget httpd php gcc glibc glibc-common gd gd-devel make net-snmp unzip
}

debian_pkgs() {
  apt-get -y update && apt-get -y upgrade &&
  apt-get install -y make wget gcc g++ libssl-dev libkrb5-dev &&
  apt-get install -y ntp curl fping nmap vim graphviz tcpdump iptraf sudo rsync gawk whois dnsutils exim4 dos2unix sysstat &&
  apt-get install -y apache2 ssl-cert libapache2-mod-auth-ntlm-winbind libfontconfig-dev vim-gtk libgd2-xpm-dev libltdl-dev libssl-dev libclass-csv-perl &&
  apt-get install -y php-pear libapache2-mod-php php-snmp php-gd php-mysql php-ldap *libmysqlclient-dev
  apt-get install -y rrdtool librrds-perl libmcrypt-dev unzip &&
  apt-get install -y snmpd snmp libnet-snmp-perl &&
  return 0
}

install_mariadb() {
  if [ $mynagiosql_host = "localhost" ]; then
    echo mysql-server-5.5 mysql-server/root_password password ${mysql_root_passwd} | debconf-set-selections &&
    echo mysql-server-5.5 mysql-server/root_password_again password ${mysql_root_passwd} | debconf-set-selections &&
    apt-get install -y mariadb-server &&
    return 0
  fi
  return 0
}

install_nagioscore() {
  user_exist ${user_nagios} ${install_path} &&
  mkdir -p ${temp_path} && cd ${temp_path} &&
  wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-${nagioscore_version}.tar.gz &&
  tar -zxf nagios-${nagioscore_version}.tar.gz &&
  cd nagios-${nagioscore_version} &&
  ./configure --prefix=${install_path} --with-nagios-user=${user_nagios} --with-nagios-group=${user_nagios} --enable-event-broker --with-htmurl=/nagios --with-init-type=${INIT_TYPE} && make all && make install && make install-init && make install-commandmode && make install-config &&
  sed -i "s/#  SSLRequireSSL/   SSLRequireSSL/g" ${temp_path}/nagios-${nagioscore_version}/sample-config/httpd.conf &&
  make install-webconf && make install-exfoliation &&
  return 0
}

configure_nagioscore() {
  /usr/bin/htpasswd -bc ${install_path}/etc/htpasswd.users nagiosadmin ${nagiosadmin_passwd} &&
  echo ${hostname} > /etc/hostname &&
  echo rocommunity nagios 127.0.0.1 >> /etc/snmp/snmpd.conf &&
  ln -sf /usr/bin/mail /bin/mail &&
  /usr/sbin/usermod -G ${user_nagios} ${user_apache} &&
  mkdir -p ${temp_path} && cd ${temp_path} &&
  cat <<EOF > index.html
<head>
<meta http-equiv="REFRESH" content="0; url=nagios/">
</head>
EOF
  mv index.html /var/www/html/index.html
  systemctl enable nagios &&
  /usr/sbin/a2enmod rewrite cgi &&
  /usr/sbin/a2enmod ssl &&
  /usr/sbin/a2ensite default-ssl &&
  service apache2 restart &&
  service nagios start &&
  return 0
}

install_nrpe() {
  curl -k https://gitlab.com/dmcico/nagios/raw/master/install_nrpe.sh | bash &&
  curl -k https://gitlab.com/dmcico/nagios/raw/master/install_nagiosplugins.sh | sh &&
  mkdir -p ${install_path}/etc/nrpe/ &&
  mkdir -p ${install_path}/libexec/other/ &&
  return 0
}

configure_nrpe() {
  wget -q https://raw.githubusercontent.com/dorancemc/nagios_core/master/conf-base/nrpe.cfg -O ${install_path}/etc/nrpe.cfg &&
  wget -q https://raw.githubusercontent.com/dorancemc/nagios_core/master/conf-base/check_base.cfg -O ${install_path}/etc/nrpe/check_base.cfg &&
  for i in check_await.sh check_cpu.sh check_iops.sh check_mem.sh check_netint.pl check_users_ip.pl; do
      wget -q https://raw.githubusercontent.com/dorancemc/nagios_core/master/check-base/${i} -O ${install_path}/libexec/other/${i} &&
      chmod 755 ${install_path}/libexec/other/${i}
  done
  chown -R nagios: ${install_path}/etc/nrpe/ &&
  chown -R nagios: ${install_path}/libexec/other/ &&
  service nrpe start &&
  return 0
}

install_pnp4nagios() {
  mkdir -p ${temp_path} && cd ${temp_path} &&
  wget http://downloads.sourceforge.net/project/pnp4nagios/PNP-0.6/pnp4nagios-${pnp4nagios_version}.tar.gz &&
  tar -zxf pnp4nagios-${pnp4nagios_version}.tar.gz && cd pnp4nagios-${pnp4nagios_version} &&
  ./configure --with-nagios-user=${user_nagios} --with-nagios-group=${user_nagios} --prefix=${install_pnp4nagios} && make all && make fullinstall &&
  return 0
}

install_grafana() {
  apt-get install -y apt-transport-https
  apt-get install -y software-properties-common wget
  wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
  add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
  apt-get update
  apt-get install grafana
  systemctl enable grafana-server
  systemctl start grafana-server
  /usr/sbin/grafana-cli plugins install sni-pnp-datasource
  systemctl restart grafana-server.service
  wget -O /opt/pnp4nagios/share/application/controllers/api.php "https://github.com/lingej/pnp-metrics-api/raw/master/application/controller/api.php"
  sed -i '/Require valid-user/a\        Require ip 127.0.0.1 ::1' /etc/apache2/sites-enabled/pnp4nagios.conf
  systemctl restart apache2.service
}

configure_pnp4nagios() {
  mkdir -p ${temp_path} && cd ${temp_path} &&
  cat <<'EOF' >> host_perfdata_file.txt
#
host_perfdata_command=process-host-perfdata
service_perfdata_command=process-service-perfdata
#
service_perfdata_file=/opt/pnp4nagios/var/service-perfdata
service_perfdata_file_template=DATATYPE::SERVICEPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tSERVICEDESC::$SERVICEDESC$\tSERVICEPERFDATA::$SERVICEPERFDATA$\tSERVICECHECKCOMMAND::$SERVICECHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$\tSERVICESTATE::$SERVICESTATE$\tSERVICESTATETYPE::$SERVICESTATETYPE$

service_perfdata_file_mode=a
service_perfdata_file_processing_interval=15
service_perfdata_file_processing_command=process-service-perfdata-file
#
host_perfdata_file=/opt/pnp4nagios/var/host-perfdata
host_perfdata_file_template=DATATYPE::HOSTPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tHOSTPERFDATA::$HOSTPERFDATA$\tHOSTCHECKCOMMAND::$HOSTCHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$

host_perfdata_file_mode=a
host_perfdata_file_processing_interval=15
host_perfdata_file_processing_command=process-host-perfdata-file
EOF

mkdir -p ${temp_path} && cd ${temp_path} &&
cat <<'EOF' >> command_perfdata_file.txt
#
define command {
 command_name process-service-perfdata-file
 command_line /bin/mv /opt/pnp4nagios/var/service-perfdata /opt/pnp4nagios/var/spool/service-perfdata.$TIMET$
}

define command {
 command_name process-host-perfdata-file
 command_line /bin/mv /opt/pnp4nagios/var/host-perfdata /opt/pnp4nagios/var/spool/host-perfdata.$TIMET$
}
EOF
  cat command_perfdata_file.txt >> $install_path/etc/objects/commands.cfg &&
  cp /etc/httpd/conf.d/pnp4nagios.conf /etc/apache2/sites-enabled/pnp4nagios.conf &&
  sed -i "s/AuthUserFile \/usr\/local\/nagios/AuthUserFile \/opt\/nagios/g" /etc/apache2/sites-enabled/pnp4nagios.conf &&
  mv ${install_pnp4nagios}/share/install.php ${install_pnp4nagios}/share/install.old &&
  sed -i "s/process_performance_data=0/process_performance_data=1/g" ${install_path}/etc/nagios.cfg &&
  file_exist ${install_path}/etc/nagios.cfg &&
  sed -i "/process_performance_data=1/r host_perfdata_file.txt" ${install_path}/etc/nagios.cfg &&
  update-rc.d npcd defaults &&
  service npcd start &&
  service npcd status &&
  return 0
}

install_nagiosql(){
  mkdir -p ${temp_path} && cd ${temp_path} &&
  wget https://gitlab.com/wizonet/nagiosql/-/archive/3.4.1-git2020-01-19/nagiosql-3.4.1-git2020-01-19.zip &&
  unzip nagiosql-3.4.1-git2020-01-19.zip && mv nagiosql-3.4.1-git2020-01-19 ${install_nagiosql} &&
  return 0
}

configure_nagiosql() {
  cat <<EOF > /etc/apache2/sites-enabled/nagiosql.conf
Alias /nagiosql  "$install_nagiosql"
<Directory "$install_nagiosql">

SSLRequireSSL
Options None
AllowOverride None
Order allow,deny
Allow from all

AuthName "Nagios Access"
AuthType Basic
AuthUserFile ${install_path}/etc/htpasswd.users
Require valid-user
#
</Directory>
EOF

cat <<EOF > ${install_nagiosql}/config/settings.php
<?php
exit;
?>
[db]
type         = mysqli
server       = ${mynagiosql_host}
port         = 3306
database     = ${mynagiosql_db}
username     = ${mynagiosql_user}
password     = ${mynagiosql_passwd}
[path]
base_url     = /nagiosql/
base_path    = ${install_nagiosql}/
EOF

  sed -i 's/^;date.timezone.*/date.timezone = "America\/Bogota"/g' /etc/php/7.0/apache2/php.ini &&
  mkdir -p ${install_path}/etc/nagiosql/hosts &&
  mkdir -p ${install_path}/etc/nagiosql/services &&
  mkdir -p ${install_nagiosql}/backup/hosts &&
  mkdir -p ${install_nagiosql}/backup/services &&
  sed -i "s/^cfg_file=/#cfg_file=/g" ${install_path}/etc/nagios.cfg &&
  echo "cfg_dir=$install_path/etc/nagiosql" >>$install_path/etc/nagios.cfg &&
  chown -R ${user_apache}:${user_nagios} ${install_path}/etc/nagiosql &&
  chown -R www-data: ${install_nagiosql}/backup/
  chown ${user_apache}.${user_nagios} ${install_path}/etc/nagios.cfg &&
  chown ${user_apache}.${user_nagios} ${install_path}/etc/cgi.cfg &&
  chown ${user_apache}.${user_nagios} ${install_path}/var/rw/nagios.cmd &&
  chmod 640 ${install_path}/etc/nagios.cfg &&
  chmod 640 ${install_path}/etc/cgi.cfg &&
  chmod 660 ${install_path}/var/rw/nagios.cmd &&
  configure_mysql_nagiosql &&
  rm -rf ${install_nagiosql}/install/ &&
  service apache2 restart &&
  return 0
  }

configure_mysql_nagiosql() {
  if [ $mynagiosql_host = "localhost" ]; then
    /usr/bin/mysql -u root -p${mysql_root_passwd} -e  "create database ${mynagiosql_db}; create user ${mynagiosql_user} identified by \"${mynagiosql_passwd}\"; grant all on ${mynagiosql_db}.* to ${mynagiosql_user}"
  fi
  /usr/bin/mysql -u ${mynagiosql_user} -p${mynagiosql_passwd} ${mynagiosql_db} <${install_nagiosql}/install/sql/nagiosQL_v341_db_mysql.sql
  # wget https://gitlab.com/dmcico/nagios/raw/master/nagios_core/nagiosqldb.sql -O ${install_nagiosql}/install/sql/nagiosqldb.sql &&
  # /usr/bin/mysql -u ${mynagiosql_user} -p${mynagiosql_passwd} ${mynagiosql_db} <${install_nagiosql}/install/sql/nagiosqldb.sql

cat <<EOF > ${install_nagiosql}/install/sql/install_queries.sql
UPDATE tbl_configtarget
SET
  basedir = '${install_path}/etc/nagiosql/',
  hostconfig = '${install_path}/etc/nagiosql/hosts/',
  serviceconfig = '${install_path}/etc/nagiosql/services/',
  backupdir = '${install_path}/etc/nagiosql/backup/',
  hostbackup = '${install_nagiosql}/backup/hosts/',
  servicebackup = '${install_nagiosql}/backup/services/',
  nagiosbasedir = '${install_path}/etc/',
  importdir = '${install_path}/etc/objects/',
  picturedir = '',
  commandfile = '${install_path}/var/rw/nagios.cmd',
  binaryfile = '${install_path}/bin/nagios',
  pidfile = '/run/nagios.lock',
  conffile = '${install_path}/etc/nagios.cfg',
  cgifile = '${install_path}/etc/cgi.cfg',
  resourcefile = '${install_path}/etc/resource.cfg',
  version = 4,
  access_group = 0,
  active = '1',
  nodelete = '1'
  WHERE id = 1;

  INSERT INTO tbl_settings VALUES (1,'db','version','3.4.1'),(2,'db','type','mysqli'),(3,'path','protocol','https'),(4,'path','tempdir','/tmp'),(5,'path','base_url','/nagiosql/'),(6,'path','base_path','${install_nagiosql}'),(7,'data','locale','en_GB'),(8,'data','encoding','utf-8'),(9,'security','logofftime','3600'),(10,'security','wsauth','1'),(11,'common','pagelines','30'),(12,'common','seldisable','1'),(13,'common','tplcheck','1'),(14,'common','updcheck','1'),(15,'network','proxy','0'),(16,'network','proxyserver',''),(17,'network','proxyuser',''),(18,'network','proxypasswd',''),(19,'network','onlineupdate','0');
  INSERT INTO tbl_user VALUES (1,'nagiosadmin','Administrator','','1','1','1','1','1',1,'','');
EOF

  /usr/bin/mysql -u ${mynagiosql_user} -p${mynagiosql_passwd} ${mynagiosql_db} <${install_nagiosql}/install/sql/install_queries.sql &&

  return 0
}

crear_backup() {
  mkdir -p /scripts
cat <<EOF > /scripts/backup.sh
#!/bin/sh
# script to delete old data and run backup
# dorancemc@
#
mkdir -p /backups
find /backups -mtime +7 -delete
find /opt/nagiosql/backup/ -mtime +7 -delete
mysqldump -u ${mynagiosql_user} -p${mynagiosql_passwd} ${mynagiosql_db} >/backups/${mynagiosql_db}-$(date +%Y%m%d%H%M%S)
EOF
  chmod 755 /scripts/backup.sh
  echo "0 0 * * * /scripts/backup.sh" | crontab
}

crear_carcelero() {
  cd ${install_path} &&
ipaddress=$(ip addr | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
cat <<EOF > .carcelero
-- nagios site --
nagios url = https://${ipaddress}/
nagios user / password = nagiosadmin / $nagiosadmin_passwd
-- nagiosql --
nagiosql user / password = nagiosadmin / $nagiosadmin_passwd
url for nagiosql: https://${ipaddress}/nagiosql
-- mariadb --
database nagiosql = $mynagiosql_user / $mynagiosql_passwd
mysql_root_passwd=$mysql_root_passwd


++ After installation ++

A. Import data:
1. go to nagiosql https://${ipaddress}/nagiosql/
2. go to import https://${ipaddress}/nagiosql/admin/import.php
3. select all elements on objects folder
4. clic on Import
5. go to verify https://${ipaddress}/nagiosql/admin/verify.php
6. clic "Do it" on 4 steps

B. Configure pnp4nagios links
1. go to service templates: https://${ipaddress}/nagiosql/admin/servicetemplates.php
2. edit configuration for all service templates
3. clic on "addon settings"
4. on Action URL, add this:
   /pnp4nagios/graph?host=\$HOSTNAME\$&srv=\$SERVICEDESC\$
5. save config
6. clic on "Write config file"
4. go to verify https://${ipaddress}/nagiosql/admin/verify.php
5. clic "Do it" on 4 steps

C. configure grafana
1. go to Grafana https://${ipaddress}:3000/
2. credentials admin/admin
3. follow this steps: https://support.nagios.com/kb/article/nagios-core-using-grafana-with-pnp4nagios-803.html#Grafana_Config

EOF
  chown ${user_nagios}: ${install_path}/.carcelero &&
  echo "# ========= access information ========= " &&
  cat ${install_path}/.carcelero &&
  return 0
}

unknown() {
  echo "distro no reconocida por este script :( "
}

run_core() {
  linux_variant &&
  $distro &&
  rm -rf ${temp_path} &&
  return 0
}

run_core
