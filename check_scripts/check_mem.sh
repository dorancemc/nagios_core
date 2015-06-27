#!/bin/bash
# Script to check mem used from free command 
# Written by: Dorance Martinez (dorancemc@gmail.com) based in check_mem of Lukasz Gogolin (lukasz.gogolin@gmail.com) 
# Requirements: free bash 
# Version 0.3
#
USAGE="`basename $0` [-w|--warning]<warning> [-c|--critical]<critical> \n \n  warnlevel and critlevel is percentage value without %"
THRESHOLD_USAGE="CRITICAL threshold must be greater than WARNING: `basename $0` $*"
warning=""
critical=""
re='^[0-9]+$'
if [[ $# -lt 4 ]] || ! [[ $2 =~ $re ]] || ! [[ $4 =~ $re ]]
then
	echo ""
	echo "Wrong Syntax: `basename $0` $*"
	echo ""
	echo -e "Usage: $USAGE"
	echo ""
	exit 2
fi
while [[ $# -gt 0 ]]
  do
        case "$1" in
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
        echo -e "Usage: $USAGE"
	echo ""
        exit 2
fi


        memTotal_b=`free -b |grep Mem |awk '{print $2}'`
        memFree_b=`free -b |grep Mem |awk '{print $4}'`
        memBuffer_b=`free -b |grep Mem |awk '{print $6}'`
        memCache_b=`free -b |grep Mem |awk '{print $7}'`

        memTotal_m=`free -m |grep Mem |awk '{print $2}'`
        memFree_m=`free -m |grep Mem |awk '{print $4}'`
        memBuffer_m=`free -m |grep Mem |awk '{print $6}'`
        memCache_m=`free -m |grep Mem |awk '{print $7}'`

        memUsed_b=$(($memTotal_b-$memFree_b-$memBuffer_b-$memCache_b))
        memUsed_m=$(($memTotal_m-$memFree_m-$memBuffer_m-$memCache_m))

        memUsedPrc=$((($memUsed_b*100)/$memTotal_b))
        memWarn=$((($memTotal_b*$warning)/100))
        memCrit=$((($memTotal_b*$critical)/100))


        if [ "$memUsedPrc" -ge "$critical" ]; then
                echo "Memory: CRITICAL Total: $memTotal_m MB - Used: $memUsed_m MB - $memUsedPrc% used!| USED=$memUsed_b;$memWarn;$memCrit;0;$memTotal_b CACHE=$memCache_b;$memWarn;$memCrit;0;$memTotal_b BUFFER=$memBuffer_b;$memWarn;$memCrit;0;$memTotal_b"
                $(exit 2)
        elif [ "$memUsedPrc" -ge "$warning" ]; then
                echo "Memory: WARNING Total: $memTotal_m MB - Used: $memUsed_m MB - $memUsedPrc% used!| USED=$memUsed_b;$memWarn;$memCrit;0;$memTotal_b CACHE=$memCache_b;$memWarn;$memCrit;0;$memTotal_b BUFFER=$memBuffer_b;$memWarn;$memCrit;0;$memTotal_b"
                $(exit 1)
        else
                echo "Memory: OK Total: $memTotal_m MB - Used: $memUsed_m MB - $memUsedPrc% used!| USED=$memUsed_b;$memWarn;$memCrit;0;$memTotal_b CACHE=$memCache_b;$memWarn;$memCrit;0;$memTotal_b BUFFER=$memBuffer_b;$memWarn;$memCrit;0;$memTotal_b"
                $(exit 0)
        fi


