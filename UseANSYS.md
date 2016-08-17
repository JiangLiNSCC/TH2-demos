> 声明：目前天河上的FLUENT 是由ANSYS提供的试用版，LICENSE 会定期的 失效 （一般是每个月底），请用户做好准备。

## 0 环境设置

```
export PATH=/WORK/app/ansys:$PATH
```

在这里我们封装了一些工具来方便用户在天河二号上更方便和更有效率的使用ANSYS 软件。



## 1 使用 ANSYS FLUENT

```
$fluent.ultra [-p <x>] [-L<x>] [-N<x>] [udf] versions -i inputfile
-p x , 可选参数，设定作业的分区，默认为work 分区 ， x 为分区名 （同 yhrun 的 -p 参数）
-x cnx , 可选参数，设定作业提交时的排出节点，如指定 -x cn123, 则不会将作业发送到 cn123节点上 （同 yhrun 的 -x 参数）
-Lx，可选参数，设定核数，x 为数字
-L0  串行
-L1  默认，8核
-L2 32核
-L3 128核
-L4 512核
-L5 2048核

-Nx，可选参数，设定结点数，x为数字，当进程占用过多内存很大无法计算时，可以考虑多分摊几个结点。

udf，可选参数
当有udf模块需要编译，设定该参数，
.c .h文件放置在工作目录, jou文件不需要再指定编译

versions 必选参数，比如2d,3d,3ddp

-i 是必选参数
```

**在 /WORK/app/ansys 目录下，我们还有fluent ， fluent1 , fluent2, fluent3 等之前发布的FLUENT 的封装工具。 目前，我们强烈推荐您使用最新的封装脚本  fluent.ultra 来代替原来的封装脚本。 fluent.ultra 对MPI 通信进行了优化，在某些较大规模的算例上可以获得数倍的性能提升，并可以获取更大的可扩展性。**

### 查看 FLUENT 的license 使用情况：
```
fluent.lmstat
```
如此结果：
```
Users of anshpc_pack:  (Total of 20 licenses issued;  Total of 20 licenses in use)
  "anshpc_pack" v9999.9999, vendor: ansyslmd
```
表明，FLUENT 有20个pack 资源，但已经都在用了。
Fluent 的每个 作业至少占用 1 个 pack 资源 ； pack 资源与可用核数之间有限制关系， x 个pack 资源 最多支持一个作业使用 8 * 4 ^ (x -1) 个作业， 即 1 ， 2， 3 个pack 资源分别最多支持 1 个 8 ， 32 ，128 核 的作业 。 由于 pack 资源比较有限， 封装的脚本里强制要求用户将 pack 资源的可用核数占满。  



# 2 MECHANICAL
```
$mech [-Lx] [-Nx] -i input [-o output]
 -Lx, 可选参数，x是数字，指定核数
    0:  串行
    1:  8核； 2:  32核；3:  128核；4:  512核；5:  2048核

-Nx，可选参数，x是数字，指定结点数目

-i 输入
-o 输出
```

# 3 LSDYNA

```
$dyna [-nx] [-Ny] i=xxx.out [o=yyy.out] [其他参数]
[]参数可选
-n 进程数
-N 结点数
i=输入
o=输出
```

