
mode=$1
weekend=`date +%w`
if [ "$mode" = "update" ];then
    cat result/user_info_recom.poi.${weekend} | python bin/select.py conf/select.conf > result/user_info_recom.dat.${weekend}
elif [ "$mode" = "rollback" ];then
    cp result/for_rollback result/user_info_recom.dat
fi

cd result
md5sum user_info_recom.dat > user_info_recom.dat.md5
cd -
   

