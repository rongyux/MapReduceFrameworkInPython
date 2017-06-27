# MapReduceFrameworkInPython
<dependency>
<p>很好用的一个mapreduce框架，加快mapreduce研发效率。
</dependency>
## Demo：
<dependency>
    按照关键字join两个大表，shuffle按照第一个key关键字分桶，前两个关键字key和tag排序。每个reduce接收到的都是相同key下，按照tag排序的两个表内容，在post处理模块做join即可。
</dependency>

## 运行说明
<dependency>
<p>功能：简易的hadoop任务调度框架
<p>说明：每次上线一个简单的hadoop任务，我们都需要编写进度管理，日志管理，配置管理，do文件管理等，十分麻烦
      简易框架将这些内容都抽象出来，提供简单的用法。 程序员只需要编写 核心的程序 program.sh 即可。
<p>用法：一次调用 sh run.sh ; 处理一段时间的 sh start.sh 时间段在start.sh 中管理
</dependency>
