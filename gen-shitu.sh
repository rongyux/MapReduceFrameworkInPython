#! /bin/sh

# ����ִ�нű������ܰ����������ڣ�
# ��1���������ݵļ��
# ��2��hadoop�ͱ��س���ĵ���
# ע�⣺�ó�����run.sh �Ļ�������ִ�У������ӽű�������Ҫ��ĩβexit

#weekend=`date -d ${PRO_DATE} +%w`
#DATE=`date +%Y%m%d`
INPUT_ALL=" -input ${PV_LOG_PATH[0]} "
INPUT_ALL=" ${INPUT_ALL} -input ${PV_LOG_PATH[1]} "
# ���������ַ
loop=${#PV_LOG_PATH[*]}
i=0
#while [ ${i} -lt ${loop} ]
#do
#   ${HADOOP} fs -ls ${PV_LOG_PATH[${i}]}
#   if [ $? -ne 0 ]
#   then
#       i=`expr $i + 1`
#       continue
#   fi
#   INPUT_ALL=" ${INPUT_ALL} -input ${PV_LOG_PATH[${i}]} "
#   WriteLog "NOTICE: pv log ${PV_DONE_FILE[${i}]} done file is ready" "${LOG_FILE}"
#   i=`expr $i + 1`
#done

$HADOOP fs -rmr ${OUTPUT_PATH}

$HADOOP  streaming \
        -D mapred.job.name=shitu_info_model \
		-D mapred.job.priority=NORMAL \
		-D num.key.fields.for.partition=1 \
		-D stream.num.map.output.key.fields=1 \
		-D stream.memory.limit=800 \
        -D mapred.map.tasks=2000 \
        -D mapred.reduce.tasks=500 \
        -D mapred.job.map.capacity=2000 \
        -D mapred.job.reduce.capacity=2000 \
	    -partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner  \
		${INPUT_ALL} \
		-output ${OUTPUT_PATH} \
		-mapper "python2.7 mapper.py" \
		-reducer "python2.7 reducer.py" \
		-file ./bin/*.py \
		-file ./data/* 

if [ $? -ne 0 ]
then
   WriteLog "${HADOOP_CMD} failed"  "${LOG_FILE}"
   exit_func "${HADOOP_CMD} failed"
fi

$HADOOP fs -touchz ${OUTPUT_PATH}/to.hadoop.done
#$HADOOP fs -cat ${OUTPUT_PATH}/* > result/${DATE}_extract.dat
#WriteLog "${HADOOP_CMD} success" "${LOG_FILE}"
