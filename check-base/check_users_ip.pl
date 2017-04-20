#!/usr/bin/perl 
#
# Copyright (C) 2016 - DMC Ingenieria SAS. http://dmci.co
# Author: Jaime Andres Cardona jacardona@outlook.com
# SPDX-License-Identifier: GPL-3.0+
#
# Descripcion: Script de validacion de usuarios
# Version: 0.1 - 12-jul-2016
#
# Objetivo      : Conocer los usuarios conectados con el comando who, sin que se repita
#                 información de las ip(s) desde donde se conectan
#
#

# **************************************************************************************
# Librerias
use POSIX;
use Getopt::Long;
Getopt::Long::config('auto_abbrev');

# **************************************************************************************
# Variables
my %RETCODES = (  'UNKNOWN' => '-1',
                    'OK' => '0',
                    'WARNING' => '1',
                    'CRITICAL' => '2');

my %CHECKCODES = ('CRITLEVEL'=>1);

# **************************************************************************************
# Capturando parametros de entrada

my $numbarg = @ARGV;

if ($numbarg < 4)
{
printf("Use: ./check_users_ip.pl -w # -c #
opciones:
		-w numero warning de conexiones
		-c numero critical de conexiones
Ejemplo: ./check_users_ip.pl -w 2 -c 4
");
exit($RETCODES{"UNKNOWN"});
}

# GetOptions ("length=i" => \$length, 	# numeric
# 			"file=s" => \$data, 		# string
# 			"verbose" => \$verbose); 	# flag

$status = GetOptions( 	"w=i" => \$warning,
						"c=i" => \$critical);

# print "w=$warning,c=$critical\n";

# **************************************************************************************
# Sacando datos del comando who

$comando = "who";
#Se quita el titulo
$contador=0;
$StrResultado="";
# who
# root     pts/0        2016-07-13 09:07 (fredy_portatil.tecnoquimicas.com)
# oraprod  pts/1        2016-07-13 10:58 (10.0.50.2)
# nagios   pts/2        2016-07-13 11:19 (172.22.4.219)


# retorna el unico proceso que consume
open(PS_F, "$comando |");

while (<PS_F>) {
($strlogin,$strtype,$fecha,$hora,$strsource) = split;
	# Se agrega a la lista si la conexión no es repetida
	if (index($StrResultado, $strsource) == -1)
	{
		$StrResultado=$StrResultado."$strlogin,$strtype,$strsource\n";
		$contador=$contador+1;
	    # print "$strlogin,$strtype,$strsource\n";
	}
	# else # Este es el caso de conexiones repetidas
	# {
	#	$StrResultado=$StrResultado."$strlogin,$strtype,$strsource-repetido\n";
	#    # print "$strlogin,$strtype,$strsource-repetido\n";
	# }

	# chomp($string);
}
close(PS_F);

# print "Conexiones=$contador\n$StrResultado";


# **************************************************************************************
# Evaluando los resultados

if ($contador >= $critical) {
		printf("CRITICAL - $contador usuarios actualmente logueados | 'conn'=$contador;$warning;$critical;0;$critical\n$StrResultado");
		exit($STATUSCODE{"CRITICAL"});
	}
	elsif ($contador >= $warning) {
			printf("WARNING - $contador usuarios actualmente logueados | 'conn'=$contador;$warning;$critical;0;$critical\n$StrResultado");
			exit($STATUSCODE{"WARNING"});
		}
		else {
			printf("OK - $contador usuarios actualmente logueados | 'conn'=$contador;$warning;$critical;0;$critical\n$StrResultado");
			exit($STATUSCODE{"OK"});
			}

printf("UNKNOWN - incapaz de determinar valor\n");
exit($STATUSCODE{"UNKNOWN"});
