#!/bin/sh
#SBATCH  -N 1 
rm -rf ~/.vnc/*  ./hostport ./log.novnc &>/dev/null
#./startvncs.tcl
# del all vncserver 
/WORK/app/TurboVNC/bin/vncserver -list | grep '^:' | cut -c 2 |  xargs -n 1 -t -i  /WORK/app/TurboVNC/bin/vncserver -kill  :{}
ps x | grep /WORK/app/TurboVNC/bin/Xvnc | awk '{print p}{p=$1}' | xargs -n 1 -t kill -9
/WORK/app/TurboVNC/bin/vncpasswd2 $VNC_PW1 $VNC_PW2
/WORK/app/TurboVNC/bin/vncserver
VNCPORT=`ps x | grep 'rfbport'| grep -v grep  | head -n 1  | awk 'BEGIN{RS="-"} {print $0}'  | grep rfbport  | awk '{print $2}'`
echo `hostname`:$VNCPORT > ./hostport 
ssh $VNC_SNNM /WORK/app/noVNC/utils/noVNC --vnc `cat hostport`  > ./log.novnc & 
sleep 10
  cat log.novnc | grep http | sed  "s/$VNC_SNNMS/$VNC_SNIP/g" > log.httpadd
wait
