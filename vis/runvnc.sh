#!/bin/sh
source ./settings.sh
echo $VNC_PW1 $VNC_PW2 $VNC_PAR
rm -r log.httpadd  > /dev/null
yhbatch -p docker server.sh 
until [ -e ./log.httpadd ]
do
 sleep 5
done
cat log.httpadd
