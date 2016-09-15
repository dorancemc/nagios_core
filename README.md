# Scripts para nagios core

Algunos scripts que encontrará aca:

* Instalar Nagios Core

* Instalar Cliente NRPE

* Instalar plugins de nagios

* Plugins de nagios varios

## Instalación cliente NRPE 3.0.1
Validado en : Debian 6+, Ubuntu 16+, Centos 6+
```
curl -k https://raw.githubusercontent.com/dorancemc/nagios_core/master/install_nrpe.sh | sh -x
```

## Instalación Nagios Plugins 2.1.3
Validado en : Debian 6+, Ubuntu 16+, Centos 6+
```
curl -k https://raw.githubusercontent.com/dorancemc/nagios_core/master/install_nagiosplugins.sh | sh -x
```
Si tiene problemas para instalar los complementos de Perl, ejecute lo siguiente:
````
wget http://search.cpan.org/CPAN/authors/id/N/NA/NAGIOS/Nagios-Monitoring-Plugin-0.51.tar.gz && tar -zxvf Nagios-Monitoring-Plugin-0.51.tar.gz && cd Nagios-Monitoring-Plugin-0.51 && perl Makefile.PL ; make ; make install 
```

