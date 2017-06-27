#!/bin/bash
ERR_LIMIT=3
ERR_RETURN=1

#	配置用户发送报警短信的服务器和端口信息
#	IPPORT[i]格式为：'IP[i]:PORT[i]'.其中IP[i]可以用服务器名代替.
#	编号从0开始，最多有9个，即到编号8.

IPPORT[0]='tc-sys-monitor00.tc:15003'
IPPORT[1]='tc-sys-monitor01.tc:15003'
IPPORT[2]='10.23.199.131:15003'
	 
function WriteLog ()
{
	fntmp_date=`date`
	fnMSG=$1
	fnLOG=$2
	echo "[$fntmp_date] $fnMSG" >> $fnLOG

}

function Alert ()
{
	fnEMAIL=$3
	fnMOBILE=$4
	fnLOG=$2
	fnMSG=$1

	
	WriteLog "$fnMSG" $fnLOG
	fninfo=`hostname`:$fnMSG\[`date +%T`\]
	echo | mail -s "$fninfo" $fnEMAIL


#add by lihaibo at 2008-6-10 start

	#statistic the number of IPPORT
        alert_idx=0
        while [ ! -z  ${IPPORT[$alert_idx]} ]
        do
                alert_idx=`expr $alert_idx + 1`
        done


        #if idx equal zero, no server is available
        #return directly
        if [  `expr $alert_idx`  -eq 0 ];then
      		WriteLog "no server:port is available!" $fnLOG
        	return
        fi
	
	#merge all IPPORT into 1 string
	alert_loop=0
	IPPORTARGS=""
	while [ $alert_loop -lt $alert_idx ]
	do
       		 if [ ! -z $IPPORT[$alert_loop] ];then
               		 IPPORTARGS="$IPPORTARGS -s ${IPPORT[$alert_loop]}"
       		 fi
       		 alert_loop=`expr $alert_loop + 1`
	done

#add by lihaibo end

	for fnMBLID in $fnMOBILE
	do
#commited by lihaibo at 2008-6-10 start
        #	gsmsend -s 10.11.0.231:15000 $fnMBLID@"$fninfo"
#commited by lihaibo end

#add by lihaibo at 2008-6-10 start
	gsmsend $IPPORTARGS $fnMBLID@"$fninfo"
#add by lihaibo end

	done
}

function Mail()
{
	fnEMAIL=$3
	fnLOG=$2
	fnMSG=$1
	WriteLog "$fnMSG" $fnLOG
	
	fninfo=`hostname`:$fnMSG\[`date +%T`\]
	echo | mail -s "$fninfo" $fnEMAIL
}

function SWget()
{
	fnUSER=$1
	fnPW=$2
	fnIP=$3
	fnFTP_PATH=$4
	fnFTP_FILE=$5
	fnTMP_PATH=$6	
	fnTMP_FILE=$7
	fnLOG=$8
	fnRATE=$9	
	fnTIMEOUT=${10}
	
	if [ $# -lt 9 ]
	then
		WriteLog "SWget args not enough" $fnlog
		exit $ERR_RETURN
	fi
	
	if [ $# -eq 9 ]
	then
		fnTIMEOUT=60
	fi

	if [ -e $fnTMP_PATH/$fnTMP_FILE ]  
	then
		rm $fnTMP_PATH/$fnTMP_FILE
	fi
	
	fntmp_count=0
	wget -q -t 0 -c -T $fnTIMEOUT --limit-rate=${fnRATE} ftp://$fnUSER:"$fnPW"@$fnIP/$fnFTP_PATH/$fnFTP_FILE -O $fnTMP_PATH/$fnTMP_FILE
	while [ $? -ne 0 -a $fntmp_count -lt $ERR_LIMIT ]
	do
		WriteLog "wget $fnIP/$fnFTP_PATH/$fnFTP_FILE Fail, Try again!" $fnLOG
		fntmp_count=`expr $fntmp_count + 1`
		wget -q -t 0 -c -T 60 --limit-rate=${fnRATE} ftp://$fnUSER:"$fnPW"@$fnIP/$fnFTP_PATH/$fnFTP_FILE -O $fnTMP_PATH/$fnTMP_FILE
	done
	if [ $fntmp_count -eq $ERR_LIMIT ]
	then
		WriteLog "wget $fnIP/$fnFTP_PATH/$fnFTP_FILE -O $fnTMP_FILE Fail, Exit"  $fnLOG
		return $ERR_RETURN
	else
	        WriteLog  "wget $fnIP/$fnFTP_PATH/$fnFTP_FILE -O $fnTMP_FILE Success"  $fnLOG	
	fi
}

#####################
#使用方法：
#  value = `CmdValue "head -n1 filename" $ERRTIME $LOG_SH "$ALERT_EMAIL" "$ALERT_MOBILE"`
#

function CmdValue()
{
	CMD=$1
	ERRTIME=$2
	LOG_SH=$3
	ALERT_EMAIL=$4
	ALERT_MOBILE=$5
	value=`eval $CMD`
	tm=0
	while [ -z "$value" ]
	do
		if [ $tm -lt $ERRTIME ]
		then
			sleep 1
			value=`eval $CMD`
			tm=`expr $tm + 1`
		else
			Alert "$CMD" "$LOG_SH" "$ALERT_EMAIL" "$ALERT_MOBILE"
			return 1
		fi
	done
	echo $value
}
