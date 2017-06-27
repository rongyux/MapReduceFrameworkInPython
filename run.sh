#! /bin/sh

# Copyright (c) 2013 Baidu.com, Inc. All Rights Reserved
# @author Li Yunlong(liyunlong@baidu.com)
# @brief ���ȿ�ܣ� run.sh Ϊ���Ƚű���programΪ����ִ�нű�
# @date 2013-03-26

# Ĭ�ϵĲ���
CONF_PATH="./conf"
CONF_FILE="program.conf"
DO_PATH="./do"
DO_FILE_NAME="program.do"
INDEX_FILE="./idx/program.idx"
SHELL_NAME="$(pwd)/$(basename $0)"
USAGE="Usage: sh $(basename ${SHELL_NAME}) [-h] \
   [-p confpath(default:${CONF_PATH})] \
   [-f confname(default:${CONF_FILE})] \
   [-i index_file(default:${INDEX_FILE})] \
   [-d do_file(default:${DO_PATH})] \
   [-t do_file_name(default:${DO_FILE_NAME})]"

# ���������в���
while getopts :hp:f:i:d:t: OPTION
do
    # �������Ϊ�մ����쳣
    if [ -z ${OPTARG} ];then
       echo "param error:-${OPTION},${USAGE}"
       exit -1
    fi

    # ��ȡ����
    case ${OPTION} in
        p)CONF_PATH=${OPTARG}
        ;;
        f)CONF_FILE=${OPTARG}
        ;;
        i)INDEX_FILE=${OPTARG}
        ;;
        d)DO_PATH=${OPTARG}
        ;;
        t)DO_FILE_NAME=${OPTARG}
        ;;
        h)echo ${USAGE}
        exit 0
        ;;
        ?)echo "WRONG USE WAY " ${USAGE}
        exit 0 
        ;;  
    esac
done

# ���do�ļ��Ƿ����
DO_FILE="${DO_PATH}/${DO_FILE_NAME}"
if [ -f "${DO_FILE}" ];then
   echo "NOTICE: ${DO_FILE} is already exist,so exit"
   exit 0;
fi
mkdir -p ${DO_PATH}
> ${DO_FILE}

# ���do�ļ������Ƿ�ɹ�
if [ ! -f  "${DO_FILE}" ];then
   echo "WARNING: create ${DO_FILE} error" 
   exit 1
fi

# �˳�����ɾ��do�ļ�
function exit_do()
{
    rm -rf ${DO_FILE}
    exit 1
}

# ���index�ļ��Ƿ����
if [ ! -f "${INDEX_FILE}" ]
then    
    echo "WARNING: file=[${INDEX_FILE}] is not exist"
    exit_do
fi

# idx�ļ��м�¼������һ��Ҫ�����ʱ��
# ��ȡ��һ��Ҫ�����ʱ��
PRO_DATE=`tail -1 ${INDEX_FILE} | awk -F"\t" '{print $1}'`
PRO_HOUR=`tail -1 ${INDEX_FILE} | awk -F"\t" '{print $2}'`
PRO_MIN=`tail -1 ${INDEX_FILE} | awk -F"\t" '{print $3}'`
TRY_TIME=`tail -1 ${INDEX_FILE} | awk -F"\t" '{print $4}'`
STEP=`tail -1 ${INDEX_FILE} | awk -F"\t" '{print $5}'`


# �ж�idx��ʽ�Ƿ���ȷ
if [ -z "${PRO_DATE}" ] || [ -z "${PRO_HOUR}" ] || [ -z "${PRO_MIN}" ] || [ -z "${TRY_TIME}" ] || [ -z "${STEP}" ];then
   echo "WARNING: idx file ${INDEX_FILE} format error"
   exit_do
fi

# ��ȡ���δ�����ɺ���һ��Ҫ�����ʱ��
NEXT_DATE=`date -d"${PRO_DATE} ${PRO_HOUR}:${PRO_MIN} ${STEP} sec" +%Y%m%d`
NEXT_HOUR=`date -d"${PRO_DATE} ${PRO_HOUR}:${PRO_MIN} ${STEP} sec" +%H`
NEXT_MIN=`date -d"${PRO_DATE} ${PRO_HOUR}:${PRO_MIN} ${STEP} sec" +%M`

# ����conf�ļ�
if [ ! -f "${CONF_PATH}/${CONF_FILE}" ]
then
    echo "${CONF_PATH}/${CONF_FILE} file doesn't exist"
    exit_do
fi

source ${CONF_PATH}/${CONF_FILE}
if [ $? -ne 0 ]
then
    echo "source ${CONF_PATH}/${CONF_FILE} file failed"
    exit_do
fi

# ���LOG·���Ƿ����
# ��������Ĭ��ֵ����
if [ -n "${LOG_PATH}" ] || [ ! -d "${LOG_PATH}" ]; then LOG_PATH="./log"; fi
if [ -z "${LOG_FILE_NAME}" ]; then LOG_FILE_NAME="program.log"; fi
mkdir -p ${LOG_PATH}

# ���log·�������Ƿ�ɹ�
if [ ! -d "${LOG_PATH}" ];then
   echo "WARNING: mkdir LOGPATH failed [LOGPATH]:${LOG_PATH}"
   exit_do
fi
LOG_FILE="${LOG_PATH}/${LOG_FILE_NAME}"

# ���غ����ű�
source ${FUNC_FILE}
if [ $? -ne 0 ]
then
    echo "source ${FUNC_FILE} file failed"
    exit_do
fi

# �쳣�˳�����,���Դ�������ᱨ��
function exit_func()
{
    local fn_log="$1"
    TRY_TIME=`expr ${TRY_TIME} + 1`
        
    if [ ${TRY_TIME} -gt ${MAX_TRY_TIME} ];then
        FIRST_TIME=`expr ${MAX_TRY_TIME} + 1`
	    TMP_MOD=`expr ${TRY_TIME} % ${RUN_WARNING_INTER}`
	
        if [ ${TRY_TIME} -eq ${FIRST_TIME} ] || [ ${TMP_MOD} -eq 0 ]
	    then
             MailMSG="�ӳٻ�����$(hostname)\n�ӳٳ���${SHELL_NAME}\n�ӳ�ʱ�Σ�${PRO_DATE}-${PRO_HOUR}${PRO_MIN}\n�ӳ�ԭ��${fn_log}\n"
             MobileMSG="[${ALARM_TITLE}][ʱ��Σ�${PRO_DATE}-${PRO_HOUR}${PRO_MIN}][host:$(hostname)]"                                                                            SendMail "${ALARM_TITLE}" "${MailMSG}" "${ALARM_MAIL}"
             SendMessage "${MobileMSG}" "${ALARM_MOBILE}" 
	    fi
    fi
    
    echo -e "${PRO_DATE}\t${PRO_HOUR}\t${PRO_MIN}\t${TRY_TIME}\t${STEP}" >> ${INDEX_FILE}
    rm -rf ${DO_FILE}
    exit 0
}

##################################
#  BEGIN PROGRAM
##################################

# ���ִ�нű�
if [ -z ${PROGRAM_NAME} ] || [ ! -f ${PROGRAM_NAME} ];then
   WriteLog "program file not exist, [program]:${PROGRAM_NAME}"
   exit_func "program file not exist, [program]:${PROGRAM_NAME}"
fi

# ���г���
# �������ʹ��source���ڵ�ǰ��shell��������
# program ִ����ϻ�ѿ���Ȩ������ǰshell����program�����Ҫexit
# program ִ�н���ļ�⣬��program ��ɣ�runֻ�������
# �������δ׼���ã�����ִ��ʧ�ܣ�����source�п�ֱ�ӵ��� exit_func������һ�ֵ���

source ${PROGRAM_NAME}

###################################
# END PROGRAM 
###################################

# �޸�idx�ļ�
echo -e "${NEXT_DATE}\t${NEXT_HOUR}\t${NEXT_MIN}\t0\t${STEP}" >> ${INDEX_FILE}

if [ $? -ne 0 ]
then
    WriteLog "NOTICE: write idx of ${NEXT_DATE}${NEXT_HOUR}${NEXT_MIN} failed" "${LOG_FILE}"
    exit_func "write idx of ${NEXT_DATE}${NEXT_HOUR}${NEXT_MIN} failed"  
fi
WriteLog "NOTICE: write idx of ${NEXT_DATE}${NEXT_HOUR}${NEXT_MIN} success" "${LOG_FILE}"

# END
WriteLog "NOTICE: SUCCESS END of ${PRO_DATE}${PRO_HOUR}${PRO_MIN}" "${LOG_FILE}"
rm -rf ${DO_FILE}

exit 0

