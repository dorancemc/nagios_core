#!/bin/bash
#
# Copyright (C) 2016 - DMC Ingenieria SAS. http://dmci.co
# Author: Dorance Martinez C dorancemc@gmail.com
# SPDX-License-Identifier: GPL-3.0+
#
# Descripcion: Script para installar nagios core
# Version: 0.3.1 - 16-apr-2017
# Validado: Debian >=8
#

nagioscore_version="4.3.2"
pnp4nagios_version="0.6.25"

temp_path="/temp/nagios_`date +%Y%m%d%H%M%S`"
install_path="/opt/nagios"
install_pnp4nagios="/opt/pnp4nagios"
install_nconf="/opt/nconf"

user_nagios="nagios"
user_apache="www-data"

mysql_root_passwd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
nagiosadmin_passwd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
mynconf_db="nconf_db"
mynconf_user="nconf_user"
mynconf_passwd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
mynconf_host="localhost"

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
  if [ $version -ge 8 ]; then
    INIT_TYPE="systemd"
  else
    INIT_TYPE="sysv"
  fi
  debian_flavor &&
  return 0
}

debian() {
  if [ $version -ge 8 ]; then
    INIT_TYPE="systemd"
  else
    INIT_TYPE="sysv"
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
  debian_pkgs &&
  install_mysql &&
  install_nagioscore &&
  configure_nagioscore &&
  install_nrpe &&
  configure_nrpe &&
  install_pnp4nagios &&
  configure_pnp4nagios &&
  install_nconf &&
  configure_nconf &&
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
  if [ "$distro" = "debian" ] && [ $version -ge 9 ]; then
    apt-get install -y libapache2-mod-php php-snmp php-gd php-mysql php-ldap *libmysqlclient-dev 
  else
    apt-get install -y php5 php5-snmp php5-gd php5-mysql php5-ldap php5-sqlite libmysqlclient-dev 
  fi
  apt-get install -y rrdtool librrds-perl libmcrypt-dev unzip &&
  apt-get install -y snmpd snmp libnet-snmp-perl &&
  return 0
}

install_mysql() {
  echo mysql-server-5.5 mysql-server/root_password password ${mysql_root_passwd} | debconf-set-selections &&
  echo mysql-server-5.5 mysql-server/root_password_again password ${mysql_root_passwd} | debconf-set-selections &&
  apt-get install -y mysql-server &&
  return 0
}

install_nagioscore() {
  user_exist ${user_nagios} ${install_path} &&
  mkdir -p ${temp_path} && cd ${temp_path} &&
  wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-${nagioscore_version}.tar.gz &&
  tar -zxf nagios-${nagioscore_version}.tar.gz &&
  cd nagios-${nagioscore_version} &&
  ./configure --prefix=${install_path} --with-nagios-user=${user_nagios} --with-nagios-group=${user_nagios} --with-htmurl=/nagios --with-init-type=${INIT_TYPE} && make all && make install && make install-init && make install-commandmode && make install-config &&
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
  update-rc.d nagios defaults &&
  /usr/sbin/a2enmod rewrite cgi &&
  /usr/sbin/a2enmod ssl &&
  /usr/sbin/a2ensite default-ssl &&
  service apache2 restart &&
  service nagios start &&
  return 0
}

install_nrpe() {
  curl -k https://raw.githubusercontent.com/dorancemc/nagios_core/master/install_nrpe.sh | bash &&
  curl -k https://raw.githubusercontent.com/dorancemc/nagios_core/master/install_nagiosplugins.sh | sh &&
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

install_nconf(){
  mkdir -p ${temp_path} && cd ${temp_path} &&
  wget http://downloads.sourceforge.net/project/nconf/nconf/1.3.0-0/nconf-1.3.0-0.tgz &&
  tar -zxf nconf-1.3.0-0.tgz && mv nconf ${install_nconf} &&
  return 0
}

configure_nconf() {
  cp ${install_nconf}/config.orig/* ${install_nconf}/config/ &&
  cp ${install_nconf}/config.orig/.file_accounts.php ${install_nconf}/config/ &&
  local tmp=$(echo ${install_nconf} | sed 's/\//\\\//g')
  sed -i "s/\$nconfdir/\"$tmp\"/g" ${install_nconf}/config/nconf.php &&
  local tmp=$(echo ${install_path} | sed 's/\//\\\//g')
  sed -i "s/\/var\/www\/nconf/$tmp/g" ${install_nconf}/config/nconf.php &&
  sed -i "s/^cfg_file=/#cfg_file=/g" ${install_path}/etc/nagios.cfg &&
  sed -i 's/$max_length = ""/$max_length = "0"/g' ${install_nconf}/modify_attr_write2db.php &&
  sed -i "s/'AUTH_ENABLED', \"0\"/'AUTH_ENABLED', \"1\"/g" ${install_nconf}/config/authentication.php
  mkdir -p ${temp_path} && cd ${temp_path} &&
  cat <<EOF > apache_nconf.conf
Alias /nconf  "$install_nconf"
<Directory "$install_nconf">

SSLRequireSSL
Options None
AllowOverride None
Order allow,deny
Allow from all

AuthName "Nagios Access"
AuthType Basic
AuthUserFile /opt/nagios/etc/htpasswd.users
Require valid-user
#
</Directory>
EOF
  mv apache_nconf.conf /etc/apache2/sites-enabled/nconf.conf

cat <<EOF > mysql.php
<?php
  define('DBHOST', '$mynconf_host');
  define('DBNAME', '$mynconf_db');
  define('DBUSER', '$mynconf_user');
  define('DBPASS', '$mynconf_passwd');
?>
EOF
  mv mysql.php $install_nconf/config/mysql.php

cat <<EOF > deployment.ini
[extract config]
type        = local
source_file = $install_nconf/output/NagiosConfig.tgz
target_file = $install_path/tmp/_nconf/
action      = extract

[copy collector config]
type        = local
source_file = $install_path/tmp/_nconf/server/
target_file = $install_path/etc/server/
action      = copy

[copy global config]
type        = local
source_file = $install_path/tmp/_nconf/global/
target_file = $install_path/etc/global/
action      = copy
reload_command = sudo /usr/sbin/service nagios reload
EOF
  mv deployment.ini $install_nconf/config/deployment.ini &&
  mkdir -p $install_path/etc/server &&
  mkdir -p $install_path/etc/global &&
  mkdir -p $install_nconf/temp/server &&
  mkdir -p $install_path/tmp/_nconf/server &&
  mkdir -p $install_path/tmp/_nconf/global &&
  chown -R $user_apache: $install_path/tmp/_nconf $install_path/etc/server $install_path/etc/global $install_nconf/temp/server &&
  chown -R $user_apache: $install_nconf/ $install_path/etc/server $install_path/etc/global &&
  chown -R $user_apache: $install_nconf/ $install_path/etc/server $install_path/etc/global &&
  echo "cfg_dir=$install_path/etc/server" >>$install_path/etc/nagios.cfg &&
  echo "cfg_dir=$install_path/etc/global" >>$install_path/etc/nagios.cfg &&
  echo 'www-data ALL = (root) NOPASSWD:/usr/sbin/service nagios reload' >>/etc/sudoers &&
  configure_mysql_nconf &&
  rm -rf $install_nconf/INSTALL/ && rm -rf $install_nconf/INSTALL.php &&
  rm -rf $install_nconf/UPDATE/ && rm -rf $install_nconf/UPDATE.php &&
  service apache2 restart &&
  return 0
  }

configure_mysql_nconf() {
  /usr/bin/curl -k https://raw.githubusercontent.com/dorancemc/nagios_core/master/nconf_base.sql >$temp_path/nconf_base.sql &&
  /usr/bin/mysql -u root -p${mysql_root_passwd} -e  "create database ${mynconf_db}; create user ${mynconf_user} identified by \"${mynconf_passwd}\"; grant all on ${mynconf_db}.* to ${mynconf_user}" &&
  /usr/bin/mysql -u ${mynconf_user} -p${mynconf_passwd} ${mynconf_db} <${install_nconf}/INSTALL/create_database.sql &&
  /usr/bin/mysql -u $mynconf_user -p$mynconf_passwd $mynconf_db <$temp_path/nconf_base.sql &&
  return 0
}


crear_carcelero() {
  cd ${install_path} &&
cat <<EOF > .carcelero
-- nagios site --
nagios url = https://host/
nagios user / password = nagiosadmin / $nagiosadmin_passwd
-- nconf --
nconf user / password = admin / nconf
url for nconf: http://host/nconf
-- mysql --
database nconf = $mynconf_user / $mynconf_passwd
mysql_root_passwd=$mysql_root_passwd
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
