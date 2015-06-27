#!/bin/bash
# Script to check iops from iostat
# iops : tps: The number of transfers per second that were issued to the device  
# Written by: Dorance Martinez (dorancemc@gmail.com)
# Requirements: lsblk, iostats, bc 
# Version 0.2
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

function one_disk {
    disk=$1
    iops=`/usr/bin/iostat -d /dev/$disk -t 2 2 | grep -n $disk | grep 9:$disk | awk '{print $2}'`
    
    if [ $(bc <<< "$iops >= $critical") -ne 0 ];
    	then
    		echo "CRITICAL: IOPS $disk = $iops | iops=$iops;$warning;$critical"
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
}

function all_disks {
    CRITICAL="CRITICAL: "
    NCRITICAL=0
    WARNING="WARNING: "
    NWARNING=0
    OK="OK: "
    NOK=0
    PERFDATA=""
    OUTPUT=""
    for disk in `lsblk -l -d -n | grep disk | awk '{print $1}' ` ; do
    iops=`/usr/bin/iostat -d /dev/$disk -t 2 2 | grep -n $disk | grep 9:$disk | awk '{print $2}'`
 
    if [ $(bc <<< "$iops >= $critical") -ne 0 ]; then
    	CRITICAL+="$disk = $iops "
        PERFDATA+=" $disk=$iops;$warning;$critical"
        NCRITICAL=$((NCRITICAL + 1))
    else 
        if [ $(bc <<< "$iops >= $warning") -ne 0 ]; then
    		WARNING+="$disk = $iops "
                PERFDATA+=" $disk=$iops;$warning;$critical"
                NWARNING=$((NWARNING + 1))
        else 
            if [ $(bc <<< "$iops <= $warning") -ne 0 ]; then
    		OK+="$disk = $iops "
                PERFDATA+=" $disk=$iops;$warning;$critical"
                NOK=$((NOK + 1))
            fi
        fi
    fi
    done 

    if [ $NCRITICAL -gt 0 ]; then
    		OUTPUT+=$CRITICAL
    fi
    if [ $NWARNING -gt 0 ]; then
    		OUTPUT+=$WARNING
    fi
    if [ $NOK -gt 0 ]; then
    		OUTPUT+=$OK
    fi
    if [ $NCRITICAL -gt 0 ]; then
    		echo "$OUTPUT | $PERFDATA"
                exit 2 
    fi
    if [ $NWARNING -gt 0 ]; then
    		echo "$OUTPUT | $PERFDATA"
                exit 1 
    fi
    if [ $NOK -gt 0 ]; then
    		echo "$OUTPUT | $PERFDATA"
                exit 0 
    fi
}

if [ "$disk" = "all" ]; then
   all_disks 
else
   one_disk $disk
fi
