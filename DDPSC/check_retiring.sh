#!/bin/bash
retiring=(`condor_status | grep Retir | cut -d'@' -f2 | cut -d '.' -f1 | sort | uniq`)
# active=`condor_q $USER | awk 'NR>4' | tac | sed '1,2d' | tac | cut -d' ' -f1`
active=(`condor_q $USER -af:h Owner RemoteHost | grep -v undefined | awk 'NR>1' | cut -d' ' -f2 | cut -d'@' -f 2 | cut -d'.' -f1 | sort | uniq`)
# active=('aerilon' 'pacifica')
IFS=:
for obj in ${active[@]}; do
    obj=":${obj}:"
    [[ ":${retiring[*]}:" =~ $obj ]] && msg="${msg}\n${obj}"
done

if [ -z "$msg" ]
then
    echo "Nothing is retiring"
else
    echo -e $msg | sed 1d | cut -d' ' -f2 | mailx -s 'ALERT: Servers retiring that you have jobs on' clizarraga@danforthcenter.org
fi
    
# echo -e $msg | sed 1d | cut -d' ' -f2 | mailx -s 'ALERT: Servers retiring that you have jobs on' clizarraga@danforthcenter.org

unset IFS

