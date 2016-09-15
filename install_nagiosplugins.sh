#!/bin/bash
#
# @dorancemc - 10-sep-2016
#
# Script para installar nagios plugins
# Validado en : Debian 6+, Ubuntu 16+, Centos 6+
#
#

NPLUGINS_version="2.1.3"
INSTALL_PATH="/tmp/nagios_`date +%Y%m%d%H%M%S`"
NAGIOS_USER="nagios"

linux_variant() {
  if [ -f "/etc/debian_version" ]; then
    distro="debian"
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
  if ! command_exists wget ; then
    apt-get install -y wget
  fi
  apt-get install -y perl
  installar_nplugins
}

rh() {
  if ! command_exists wget ; then
    yum install wget -y
  fi
  yum install -y perl
  installar_nplugins
}

unknown() {
  echo "distro no reconocida por este script :( "
}

installar_nplugins() {
  mkdir -p ${INSTALL_PATH}
  cd ${INSTALL_PATH} && wget http://www.nagios-plugins.org/download/nagios-plugins-${NPLUGINS_version}.tar.gz && tar -zxvf nagios-plugins-${NPLUGINS_version}.tar.gz && cd nagios-plugins-${NPLUGINS_version} && ./configure --prefix=/opt/nagios/ --enable-threads=posix --with-nagios-user=${NAGIOS_USER} --with-nagios-group=${NAGIOS_USER} --with-mysql --with-gnutls --with-ipv6 --with-openssl && make && make install
  yes | perl -MCPAN -E 'install Nagios::Monitoring::Plugin'
}

run_core() {
  linux_variant
  $distro
}

run_core
