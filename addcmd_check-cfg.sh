#!/bin/bash
#
# script para agregar check commands
# al archivo de configuracion
# del cliente nrpe
#
# uso:
# 1. crear un archivo hosts.txt e incluya los hosts (direccion ip)
#    para modificar el archivo check.cfg
# 2. reemplace el commando en COMMANDARG
# 3. coloque un comentario en COMMENT
# 4. indique la ruta en CHECK_CFG
# 5. ejecute el comando 
#    $ for i in `cat hosts.txt ` ; do ssh nagios@$i <addcmd_check-cfg.sh ; done
#
#    si tienes problemas para reiniciar el servicio desde otro usuario, ejecutas:
#    for i in `cat hosts.txt ` ; do ssh nagios@$i -t sudo /etc/init.d/nrpe restart ; done
#
# dorancemc@gmail.com - 24 jun 2015
#

COMMANDARG="command[check_swap]=/opt/nagios/libexec/check_swap  -w \$ARG1$ -c \$ARG2$"
COMMENT="# - `date`"
# echo $COMMANDARG
COMMAND=`echo $COMMANDARG | cut -f 2 -d'[' | cut -f 1 -d ']'`
# echo $COMMAND
CHECK_CFG="/opt/nagios/etc/nrpe/check.cfg"
# echo $CHECK_CFG

echo "==== `hostname` ===="
if [[ `grep $COMMAND $CHECK_CFG | wc -l` -gt 0 ]]; then
    echo "!!! el comando existe en el archivo $CHECK_CFG"
    grep $COMMAND $CHECK_CFG
else
    echo $COMMENT >> $CHECK_CFG
    echo $COMMANDARG >> $CHECK_CFG
    if [[ `grep $COMMAND $CHECK_CFG | wc -l` -eq 1 ]]; then
        grep $COMMAND $CHECK_CFG
        sudo /etc/init.d/nrpe restart
        if [[ $? -eq 0 ]]; then
            echo "el servicio fue reiniciado correctamente"
        else
            echo "!!! el servicio no se reinicio correctamente"
        fi
    else
        echo "!!! el comando no fue agregado correctamente"
    fi
fi
