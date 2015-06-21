#!/bin/bash
# Script to check iops from iostat
# iops : tps: The number of transfers per second that were issued to the device  
# Written by: Dorance Martinez (dorancemc@gmail.com)
# Requirements: iostats, bc 
# Version 0.1
#
USAGE="`basename $0` [-d]<sdx disk> [-w|--warning]<iops warning> [-c|--critical]<iops critical>"
THRESHOLD_USAGE="CRITICAL threshold must be greater than WARNING: `basename $0` $*"
disk=""
critical=""
warning=""
if [[ $# -lt 6 ]]
then
	echo ""
	echo "Wrong Syntax: `basename $0` $*"
	echo ""
	echo "Usage: $USAGE"
	echo ""
	exit 0
fi
while [[ $# -gt 0 ]]
  do
        case "$1" in
               -d)
               shift
               disk=$1
        ;;
               -w|--warning)
               shift
               warning=$1
        ;;
               -c|--critical)
               shift
               critical=$1
        ;;
        esac
        shift
  done
if [[ $warning -eq $critical || $warning -gt $critical ]]
then
	echo ""
	echo "$THRESHOLD_USAGE"
	echo ""
        echo "Usage: $USAGE"
	echo ""
        exit 0
fi

iops=`/usr/bin/iostat -d /dev/$disk -t 2 2 | grep -n $disk | grep 9:$disk | awk '{print $2}'`

if [ $(bc <<< "$iops >= $critical") -ne 0 ];
	then
		echo "CRITICAL: The number of transfers per second = $iops | iops=$iops;$warning;$critical"
		exit 2
fi
if [ $(bc <<< "$iops >= $warning") -ne 0 ];
        then
                echo "WARNING: The number of transfers per second = $iops | iops=$iops;$warning;$critical"
                exit 1
fi
if [ $(bc <<< "$iops <= $warning") -ne 0 ];
        then
                echo "OK: The number of transfers per second = $iops | iops=$iops;$warning;$critical"
                exit 0
fi
