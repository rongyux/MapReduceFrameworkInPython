#! /bin/sh

# 程序启动示例
# 可以不指定参数，则采用默认参数
# 提供了分时段调度的控制

# 步长(单位为秒)
#step=604800
step=86400

# 设置开始结束时间
begdate=20170319
enddate=20170601
begtime=0000
endtime=2345

# 修改idx文件
index_file="./idx/program.idx"
echo -e "${begdate}\t${begtime:0:2}\t${begtime:2:2}\t0\t${step}" >> ${index_file}

cur_pvtime=`date -d"${begdate} ${begtime:0:2}:${begtime:2:2} ${step} sec" +%s`
end_pvtime=`date -d"${enddate} ${endtime:0:2}:${endtime:2:2} ${step} sec" +%s`

while [ ${cur_pvtime} -le ${end_pvtime} ]
do

    # 主程序
    sh -x run.sh -p ./conf -f program.conf -i ./idx/program.idx -t program.do  1>>./log/program_check.log 2>&1

    # 设置时间
    cur_date=`tail -1 ${index_file} | awk -F"\t" '{print $1}'`
    cur_hour=`tail -1 ${index_file} | awk -F"\t" '{print $2}'`
    cur_min=`tail -1 ${index_file} | awk -F"\t" '{print $3}'`
    cur_pvtime=`date -d"${cur_date} ${cur_hour}:${cur_min} ${step} sec" +%s`
done

exit 0
