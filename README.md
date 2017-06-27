# MapReduceFrameworkInPython
很好用的一个mapreduce框架，加快mapreduce研发效率。

demo：
    按照关键字join两个大表，shuffle按照第一个key关键字分桶，前两个关键字key和tag排序。每个reduce接收到的都是相同key下，按照tag排序的两个表内容，在post处理模块做join即可。


运行说明：
