#!/bin/bash
#
# @dorancemc - 14-sep-2016
#
# Script para installar nrpe
# Validado en : Debian 7+, Ubuntu 16+, Centos 6+
#
#

NRPE_version="3.0.1"
INSTALL_PATH="/tmp/nagios_`date +%Y%m%d%H%M%S`"
NAGIOS_USER="nagios"

linux_variant() {
  if [ -f "/etc/debian_version" ]; then
    if ! command_exists lsb_release ; then
      apt-get install -y lsb-release
    fi
    distro=$(lsb_release -s -i | tr '[:upper:]' '[:lower:]')
    flavour=$(lsb_release -s -c )
    nversion=$(lsb_release -s -r | cut -d. -f1 )
  elif [ -f "/etc/redhat-release" ]; then
    distro="rh"
  else
    distro="unknown"
  fi
}

command_exists () {
    type "$1" &> /dev/null ;
}

debian() {
  if [ $nversion -ge 8 ]; then
    INIT_TYPE="systemd"
  else
    INIT_TYPE="sysv"
  fi
  apt-get install -y git gcc libssl-dev libkrb5-dev make libmysqlclient-dev fping
  installar_nrpe
}

rh() {
  if ! command_exists wget ; then
    yum install wget -y
  fi
  yum install -y git gcc make fping krb5-devel mysql-devel openssl-devel
  installar_nrpe
}

unknown() {
  echo "distro no reconocida por este script :( "
}

installar_nrpe() {
  git clone https://github.com/NagiosEnterprises/nrpe.git ${INSTALL_PATH}/nrpe-${NRPE_version}
  cd ${INSTALL_PATH}/nrpe-${NRPE_version} && ./configure --prefix=/opt/nagios/ --enable-ssl --enable-command-args --with-nrpe-user=${NAGIOS_USER} --with-nrpe-group=${NAGIOS_USER} --with-nagios-user=${NAGIOS_USER} --with-nagios-group=${NAGIOS_USER} --with-opsys=linux --with-dist-type=${distro} --with-init-type=${INIT_TYPE}
  mkdir -p /opt/nagios && groupadd -r ${NAGIOS_USER} && useradd -g ${NAGIOS_USER} -d /opt/nagios ${NAGIOS_USER} && chown -R ${NAGIOS_USER}: /opt/nagios/
  make all && make install && make install-plugin && make install-daemon && make install-config && make install-init
}

run_core() {
  linux_variant
  $distro
}

run_core
