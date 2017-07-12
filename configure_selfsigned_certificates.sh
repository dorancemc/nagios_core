#!/bin/bash
#
# Copyright (C) 2016 - DMC Ingenieria SAS. http://dmci.co
# Author: Dorance Martinez C dorancemc@gmail.com
# SPDX-License-Identifier: GPL-3.0+
#
# Descripcion: Script para crear certificados para un sitio web
# Version: 0.1.1 - 09-dic-2016
# Validado: Debian >=8
#
#

# Setup Variables
country=CO
state=ValleDelCauca
locality=Cali
organization=company.local
organizationalunit=monitoring
servername=nagios
email=support@company.local
days=365
apache_user="www-data"
ca_path="/etc/ssl"

mkdir -p ${ca_path} &&
openssl req -nodes -newkey rsa:2048 -keyout ${ca_path}/${servername}.key -out ${ca_path}/${servername}.csr -days ${days} -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$servername/emailAddress=$email" &&
cp -v ${ca_path}/${servername}.key ${ca_path}/${servername}.original &&
openssl rsa -in ${ca_path}/${servername}.original -out ${ca_path}/${servername}.key &&
rm -v ${ca_path}/${servername}.original &&
openssl x509 -req -days ${days} -in ${ca_path}/${servername}.csr -signkey ${ca_path}/${servername}.key -out ${ca_path}/${servername}.crt &&
rm -v ${ca_path}/${servername}.csr &&
chown -R ${apache_user}: ${ca_path} &&
chmod 600 ${ca_path}/${servername}.*
