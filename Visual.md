# 天河二号可视化环境

* 应用背景
* 远程可视化方案简介
* X11 转发
* VNC 远程桌面
* 海量数据并行可视化软件 --- ParaView

## 应用背景
对于很多有成熟图形界面的用户来说。
平时，使用电脑来做计算是这样的：

![FLUENT](http://s15.sinaimg.cn/middle/794cebfb0774be101791e&690)

而要使用高性能计算机，我们得这样：
![PUTTY SHELL](http://ninghao.net/files/styles/large/public/images/blog/1503.png)

熟悉的图形操作不行了，还得学习一堆新知识
![nscc-docs](http://o8e06sulr.bkt.clouddn.com/image/jpg/nscc%E8%B5%84%E6%96%99%E4%B8%8B%E8%BD%BD.JPG)

然后还要RTFM，查看应用软件怎么在命令行模式下使用。

同时，面对很大的计算任务,我们需要花费大量的时间在上传、下载文件上。

```
graph TB
本地1-->|上传算例 600MB 10min|服务器1
服务器1 -->|计算出结果 12GB 1hour |服务器2
服务器2 -->|下载结果 12GB 3hour20min |本地2
本地2 -->|查看结果是否正确 10min|本地3
```

如何解决？

***HPC + 可视化  --->  一站式服务***

## 远程可视化方案简介

>以下5张图片及内容参考NVDIA白皮书[Remote Visualization on Server-Class Tesla GPUs](http://wenku.baidu.com/link?url=5mlRtYKtsOmcDCkO7b0_cvFuxg0FdcbbqGsp1AFTeX4CmrCMFeSw35OeOQzl4FX-i1RAbWe19G1JvD0N2eCI9ecIbwSKuAGUWY4f4pBo00u)

### HPC 集群架构

HPC集群在使用时一般都是通过网络连接到集群的头节点来进行远程访问,所以我们需要远程可视化的支持。
![HPC](http://o8e06sulr.bkt.clouddn.com/image/jpg/vis/1.JPG)

### Linux X 本地渲染

而在本地渲染模式下，Linux 图形环境时构成调用如下：

图形应用程序使用 Xlib 或 libGL 来获取图形化的支持，Xlib 会去访问 X Server,进而去访问底层图形驱动 ，  libGL 可以去访问 X Server ，也可以回去直接访问图形驱动。 


![Local](http://o8e06sulr.bkt.clouddn.com/image/jpg/vis/2.JPG)


### X11 Forward （ X11 转发 ）


Linux X 环境本身就提供了远程可视化的支持，如果客户机上装有 X Server 环境，那么运行在服务器上的图形程序可以在客户机上使用客户机的资源进行绘制。


![Remote](http://o8e06sulr.bkt.clouddn.com/image/jpg/vis/3.JPG)

### Remote Rendering with Rendering Application
一些应用程序自身采用CS架构。在服务器上进行渲染处理，将结果返回给客户端的程序，通过这种方法实现远程可视化。

一些大型的可视化软件提供这种模式的远程可视化支持，如ParaView。目前大部分的远程可视化环境 如 VNC , NX 等也都是采用这种模式。


![Remote](http://o8e06sulr.bkt.clouddn.com/image/jpg/vis/4.JPG)

### Remote Visualization with Interposer Library
通过应用程序来进行远程可视化存在适用性方面的问题，另外一些客户端的显示硬件往往也没有得到利用。而通过 VGL 则可以解决此问题。
![Remote](http://o8e06sulr.bkt.clouddn.com/image/jpg/vis/5.JPG)


各种远程方案总结：

模式 | 性能 | 软件适配性 | 目前状态 
---|---|--- |---
X11 转发 | * *  | * * * * | docker 可用 
基于软件的远程可视化 | * * * * | * * | docker 可用*
基于中间库的远程可视化 | * * * * | * * * * | 测试中




### Linux X11 转发 （x11 forwarding）
*推荐用于 **轻量级** 的偶尔的可视化需求* ,也是目前的主要的可视化方案
>[X Window System](https://en.wikipedia.org/wiki/X_Window_System)

![KDE](http://imgsrc.baidu.com/forum/w%3D580/sign=29094ce7c8177f3e1034fc0540ce3bb9/28e7fc039245d6882cfe6cf5a5c27d1ed31b24fa.jpg)
![mac](https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Gnome-screenshot-full.jpg/1280px-Gnome-screenshot-full.jpg)
始于1984，是UNIX、类UNIX、以及OpenVMS等操作系统所一致适用的标准化软件工具包及显示架构的运作协议。

X只是工具包及架构规范，X.Org是其最为普遍且最受欢迎的实现，X11是X.Org所用的协议版本。

X采用C/S的架构模型，由一个X服务器与多个X客户端程序进行通讯，服务器接受对于图形输出（窗口）的请求并反馈用户输入（键盘、鼠标、触摸屏）

![X架构](https://upload.wikimedia.org/wikipedia/commons/thumb/0/03/X_client_server_example.svg/250px-X_client_server_example.svg.png)

X的一大特点在于“网络透明性”[2]：应用程序（“客户端”应用程序）所运行的机器，不一定是用户本地的机器（显示的“服务器”）。

**天河二号上提供了X环境的支持(登陆节点、docker计算节点)，但需要用户自己的终端环境有X Server 的支持**
* 天河二号普通计算节点不支持X 环境，docker 计算节点支持
#### 测试终端是否支持 X Server 功能 
在终端环境的登陆节点，运行``` xclock ```
顺利的话会显示一个图形时钟，![xclock](http://www.ibm.com/developerworks/cn/aix/library/au-tunnelingssh/figure7.jpg)
,不顺利的话,会有出错信息：

``` Error: Can't open display ```

支持X环境的终端
* Windows 下的SSH 工具 ,配置连接时注意开启 X 转发
    * [**MobaXterm**](http://mobaxterm.mobatek.net/)  推荐,免费，易安装
    * XManager 完整版才支持X环境，免费版不支持，使用方便，性能好
    * putty + Xming 免费，安装较复杂，性能较差
    * ... ... 
* Linux 环境
    *  如果安装了图形环境就已经支持了，SSH 连接时需要使用 -X 或 -Y 参数
    *  ``` ssh -i ~/key/mykey -X userxxx@172.16.22.11  ```
* Mac OS X 
    * 类似 Linux , 但可能需要额外安装 XQuartz 
    
X 环境的问题?
* 性能
* 稳定性
* 带宽占用大

### VNC* 远程桌面

比X11 环境性能要好。

目前可供测试的可视化环境。未来的可视化平台的基础。

适合 Fluent 等商业软件的使用 。

>[VNC](https://en.wikipedia.org/wiki/Virtual_Network_Computing)
>
>VNC（Virtual Network Computing），为一种使用RFB协议的屏幕画面分享及远程操作软件。此软件借由网络，可发送键盘与鼠标的动作及即时的屏幕画面。
>
>VNC与操作系统无关，因此可跨平台使用，例如可用Windows连接到某Linux的电脑，反之亦同。甚至在没有安装客户端程序的电脑中，只要有支持JAVA的浏览器，也可使用。

[天河VPN](https://github.com/JiangLiNSCC/TH2-demos/blob/master/Use%20VNC%20.ipynb)

* **目前转发服务器 ln6 故障中**
* **目前在采购GPU ，以支持高性能的渲染环境**
```
  $source runvnc.sh
123456 654321 docker
Submitted batch job 416772
    http://172.16.23.16:6080/vnc.html?host=172.16.23.16&port=6080
```

![use vnc](https://camo.githubusercontent.com/b44d165df09b2418fe6cfa48fe171e2dbc3d1ab1/68747470733a2f2f636c6f75642e67697468756275736572636f6e74656e742e636f6d2f6173736574732f31353035383234362f31353533383334342f32346162383162342d323261652d313165362d393436322d6662643939306565656562362e6a7067)

### 在采购的商业远程可视化软件

进行中

## 海量数据并行可视化软件

#### ParaView

![ParaView 的模式](http://o8e06sulr.bkt.clouddn.com/ParaViewMode.png)

并行渲染

```
...
yhrun -N 2 -n 48  pvserver --use-offscreen-rendering --disable-xdisplay-test --mpi &
...
```

![体渲染效果图](http://o8e06sulr.bkt.clouddn.com/image/jpgParaView-under.JPG)

并行渲染测试，测试用例有 7,465,946 个单元， Abaqus 输出文件大小 82 GB. 

![天河二号上的并行渲染测试](http://o8e06sulr.bkt.clouddn.com/image/jpgParaView-timer.JPG)

