#! /bin/sh

# Copyright (c) 2013 Baidu.com, Inc. All Rights Reserved
# @author Li Yunlong(liyunlong@baidu.com)
# @brief 调度框架： run.sh 为调度脚本，program为程序执行脚本
# @date 2013-03-26

# 默认的参数
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

# 处理命令行参数
while getopts :hp:f:i:d:t: OPTION
do
    # 处理参数为空串的异常
    if [ -z ${OPTARG} ];then
       echo "param error:-${OPTION},${USAGE}"
       exit -1
    fi

    # 获取参数
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

# 检查do文件是否存在
DO_FILE="${DO_PATH}/${DO_FILE_NAME}"
if [ -f "${DO_FILE}" ];then
   echo "NOTICE: ${DO_FILE} is already exist,so exit"
   exit 0;
fi
mkdir -p ${DO_PATH}
> ${DO_FILE}

# 检查do文件创建是否成功
if [ ! -f  "${DO_FILE}" ];then
   echo "WARNING: create ${DO_FILE} error" 
   exit 1
fi

# 退出并且删除do文件
function exit_do()
{
    rm -rf ${DO_FILE}
    exit 1
}

# 检查index文件是否存在
if [ ! -f "${INDEX_FILE}" ]
then    
    echo "WARNING: file=[${INDEX_FILE}] is not exist"
    exit_do
fi

# idx文件中记录的是下一个要处理的时间
# 获取下一个要处理的时间
PRO_DATE=`tail -1 ${INDEX_FILE} | awk -F"\t" '{print $1}'`
PRO_HOUR=`tail -1 ${INDEX_FILE} | awk -F"\t" '{print $2}'`
PRO_MIN=`tail -1 ${INDEX_FILE} | awk -F"\t" '{print $3}'`
TRY_TIME=`tail -1 ${INDEX_FILE} | awk -F"\t" '{print $4}'`
STEP=`tail -1 ${INDEX_FILE} | awk -F"\t" '{print $5}'`


# 判断idx格式是否正确
if [ -z "${PRO_DATE}" ] || [ -z "${PRO_HOUR}" ] || [ -z "${PRO_MIN}" ] || [ -z "${TRY_TIME}" ] || [ -z "${STEP}" ];then
   echo "WARNING: idx file ${INDEX_FILE} format error"
   exit_do
fi

# 获取本次处理完成后，下一个要处理的时间
NEXT_DATE=`date -d"${PRO_DATE} ${PRO_HOUR}:${PRO_MIN} ${STEP} sec" +%Y%m%d`
NEXT_HOUR=`date -d"${PRO_DATE} ${PRO_HOUR}:${PRO_MIN} ${STEP} sec" +%H`
NEXT_MIN=`date -d"${PRO_DATE} ${PRO_HOUR}:${PRO_MIN} ${STEP} sec" +%M`

# 加载conf文件
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

# 检查LOG路径是否存在
# 不存则按照默认值创建
if [ -n "${LOG_PATH}" ] || [ ! -d "${LOG_PATH}" ]; then LOG_PATH="./log"; fi
if [ -z "${LOG_FILE_NAME}" ]; then LOG_FILE_NAME="program.log"; fi
mkdir -p ${LOG_PATH}

# 检查log路径创建是否成功
if [ ! -d "${LOG_PATH}" ];then
   echo "WARNING: mkdir LOGPATH failed [LOGPATH]:${LOG_PATH}"
   exit_do
fi
LOG_FILE="${LOG_PATH}/${LOG_FILE_NAME}"

# 加载函数脚本
source ${FUNC_FILE}
if [ $? -ne 0 ]
then
    echo "source ${FUNC_FILE} file failed"
    exit_do
fi

# 异常退出函数,尝试次数过多会报警
function exit_func()
{
    local fn_log="$1"
    TRY_TIME=`expr ${TRY_TIME} + 1`
        
    if [ ${TRY_TIME} -gt ${MAX_TRY_TIME} ];then
        FIRST_TIME=`expr ${MAX_TRY_TIME} + 1`
	    TMP_MOD=`expr ${TRY_TIME} % ${RUN_WARNING_INTER}`
	
        if [ ${TRY_TIME} -eq ${FIRST_TIME} ] || [ ${TMP_MOD} -eq 0 ]
	    then
             MailMSG="延迟机器：$(hostname)\n延迟程序：${SHELL_NAME}\n延迟时段：${PRO_DATE}-${PRO_HOUR}${PRO_MIN}\n延迟原因：${fn_log}\n"
             MobileMSG="[${ALARM_TITLE}][时间段：${PRO_DATE}-${PRO_HOUR}${PRO_MIN}][host:$(hostname)]"                                                                            SendMail "${ALARM_TITLE}" "${MailMSG}" "${ALARM_MAIL}"
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

# 检测执行脚本
if [ -z ${PROGRAM_NAME} ] || [ ! -f ${PROGRAM_NAME} ];then
   WriteLog "program file not exist, [program]:${PROGRAM_NAME}"
   exit_func "program file not exist, [program]:${PROGRAM_NAME}"
fi

# 运行程序
# 这里必须使用source，在当前的shell环境运行
# program 执行完毕会把控制权交给当前shell，在program里，不需要exit
# program 执行结果的检测，由program 完成，run只负责调度
# 如果上游未准备好，或者执行失败，则在source中可直接调用 exit_func结束这一轮调度

source ${PROGRAM_NAME}

###################################
# END PROGRAM 
###################################

# 修改idx文件
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

