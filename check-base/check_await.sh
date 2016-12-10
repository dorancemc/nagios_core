#!/bin/bash
# Script to check await from iostat
# await : The average time (milliseconds) for I/O requests  
# Written by: Dorance Martinez (dorancemc@gmail.com)
# Requirements: iostats and dc 
# Version 0.2
#
USAGE="`basename $0` [-d]<disk sdx> [-w|--warning]<await warning> [-c|--critical]<await critical>"
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

interactions=6
total=0 
for i in `iostat -mdx /dev/$disk 2 $interactions | grep -v await | awk '{print $10}' ` ; do 
    total=$(echo $total $i + p | dc ) 
done
nterm=`echo $interactions 1 - p | dc`
await=`echo $total $nterm / p | dc`

if [ $(bc <<< "$await >= $critical") -ne 0 ];
	then
		echo "CRITICAL: The average time (milliseconds) for I/O requests = $await | await=$await;$warning;$critical"
		exit 2
fi
if [ $(bc <<< "$await >= $warning") -ne 0 ];
        then
                echo "WARNING:  The average time (milliseconds) for I/O requests = $await | await=$await;$warning;$critical"
                exit 1
fi
if [ $(bc <<< "$await <= $warning") -ne 0 ];
        then
                echo "OK:  The average time (milliseconds) for I/O requests = $await | await=$await;$warning;$critical"
                exit 0
fi


