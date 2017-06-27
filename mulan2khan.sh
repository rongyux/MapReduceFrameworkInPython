
function mulan2khan()
{
    root_mulan=$1
    root_khan=$2 
    $HADOOP_KHAN_BIN fs -rmr ${root_khan}
    $HADOOP_KHAN_BIN distcp \
    -D mapred.job.priority=VERY_HIGH \
    -su app,app \
    -du fcr,SaK2VqfEDeXzKPor \
    hdfs://nmg01-mulan-hdfs.dmop.baidu.com:54310/${root_mulan} hdfs://nmg01-khan-hdfs.dmop.baidu.com:54310/${root_khan}
}  

HADOOP_KHAN_BIN="/home/users/rongyu01/hadoop-client/hadoop-client-nmg/hadoop/bin/hadoop"
IN=/app/ecom/fcr-model/rongyu01/flow_model/data/fe_format/20170402
OUT=/app/ecom/fcr/localfc-flow-basedata/data/format_shitu_fea/train/20170402
mulan2khan "${IN}" "${OUT}" 

