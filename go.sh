rm -rf do/program.do
sh -x run.sh -p ./conf -f program.conf -i ./idx/program.idx -t program.do  1>./log/program_check.log 2>&1
