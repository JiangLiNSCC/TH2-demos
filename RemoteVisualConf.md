# NVIDIA GPU REMOTE VISUALIZATION CONFIG
> [REMOTE VISUALIZATION ON SERVER-CLASS TESLA GPUS](http://docplayer.net/8322414-Remote-visualization-on-server-class-tesla-gpus.html)

## 基本配置

### 0 检查 PCI 状态
```
lspci | grep -i nvidia 
```
对于这次测试的 1060 ， 结果显示 ：
```
83:00.0 VGA compatible controller: NVIDIA Corporation Device 1c03 (rev a1)
83:00.1 Audio device: NVIDIA Corporation Device 10f1 (rev a1)
```
说明 NVIDIA 视频设备 （VGA） 已经成功在PCI 上识别（也可以直接用```lspci | grep VGA  ``` 查显卡设备信息）。

### 1 查询和设置 GPU 工作模式 
   
  ```
  nvidia-smi --query-gpu=gom.current --format=csv
  ```
  对于 NVIDIA GTX 1060 , 显示的结果是：
  ```
  gom.current
  [Not Supported]
  ```
  对于专门用于显示的系列 GTX , 并没有不同的模式，只能用于渲染。而对于集成了计算和显示的卡，可能会有 “All_on”, “Compute”,  “low DP” 等模式 ， 需要使用 ```nvidia-smi –-gom=0``` 将其设置为 “All_on” .但老版本的计算卡（如M2050） , 无法通过改模式来支持显示。
  
### 2 设置 XORG.CONF (需 sudo权限)
 
  首先，检查 GPU 设备信息： 
  ```
  nvidia-xconfig --query-gpu-info
  ```
  本测试结果 ： 
  ```
  Number of GPUs: 1

GPU #0:
  Name      : Graphics Device
  UUID      :
  GPU-e7923f01-be9b-b21e-846c-7706ff892fcf
  PCI BusID : PCI:131:0:0

  Number of Display Devices: 0
  ```
  正常检查到1块GPU ， 占用的PCI BusID 为 PCI:131:0:0 ， 并且没有接显示器 。
  
  接着，通过命令生成新的 xorg.conf 信息：
  ``` 
  nvidia-xconfig --busid=PCI:4:0:0 --use-display-device=none
  ```
  
  这时候检查 /etc/X11/xorg.conf 文件的内容如下 ： 
  
```  

Section "ServerLayout"
    Identifier     "Layout0"
    Screen      0  "Screen0" 0 0
    #InputDevice    "Keyboard0" "CoreKeyboard"
    #InputDevice    "Mouse0" "CorePointer"
EndSection

Section "Files"
EndSection

Section "InputDevice"

    # generated from default
    Identifier     "Mouse0"
    Driver         "mouse"
    Option         "Protocol" "auto"
    Option         "Device" "/dev/input/mice"
    Option         "Emulate3Buttons" "no"
    Option         "ZAxisMapping" "4 5"
EndSection

Section "InputDevice"

    # generated from data in "/etc/sysconfig/keyboard"
    Identifier     "Keyboard0"
    Driver         "kbd"
    Option         "XkbLayout" "us"
    Option         "XkbModel" "pc105"
EndSection

Section "Monitor"
    Identifier     "Monitor0"
    VendorName     "Unknown"
    ModelName      "Unknown"
    HorizSync       28.0 - 33.0
    VertRefresh     43.0 - 72.0
    Option         "DPMS"
EndSection

Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    BusID          "131:0:0"
EndSection

Section "Screen"
    Identifier     "Screen0"
    Device         "Device0"
    Monitor        "Monitor0"
    DefaultDepth    24
    Option         "ConstantFrameRateHint" "True"
    Option         "UseDisplayDevice" "none"
    SubSection     "Display"
    Depth       24
    EndSubSection
EndSection
```
   这个 xorg.conf 主要是 nvidia-xconfig 在 原有的基础上，加上了对应显卡的 Device Section , 以及在 Screen Section 里面加上了 Option "UseDisplayDevice" "none" 来支持远程渲染以及 Option "ConstantFrameRateHint" "True" 来提高远程渲染的稳定性。


   不过这个 xorg.conf 还是会有些问题 ， 参考 NVIDIA 的示例的 xorg.conf 文件 进一步进行了一下修改 ：
   * 注释掉了 Section "Screen" 中的  Monitor,DefaultDepth,SubSection至EndSubSection 。
   * 添加了一段 ：
```
  Section "ServerFlags"
    Option "IgnoreABI" "True"
    Option "nolisten" "True"
    Option "AutoAddDevices" "False"
EndSection
```  
   
   目前可以正常工作的 xorg.conf 如下： 
```  
  Section "ServerFlags"
    Option "IgnoreABI" "True"
    Option "nolisten" "True"
    Option "AutoAddDevices" "False"
EndSection

Section "ServerLayout"
    Identifier     "Layout0"
    Screen      0  "Screen0" 0 0
    #InputDevice    "Keyboard0" "CoreKeyboard"
    #InputDevice    "Mouse0" "CorePointer"
EndSection

Section "Files"
EndSection

Section "InputDevice"

    # generated from default
    Identifier     "Mouse0"
    Driver         "mouse"
    Option         "Protocol" "auto"
    Option         "Device" "/dev/input/mice"
    Option         "Emulate3Buttons" "no"
    Option         "ZAxisMapping" "4 5"
EndSection

Section "InputDevice"

    # generated from data in "/etc/sysconfig/keyboard"
    Identifier     "Keyboard0"
    Driver         "kbd"
    Option         "XkbLayout" "us"
    Option         "XkbModel" "pc105"
EndSection

Section "Monitor"
    Identifier     "Monitor0"
    VendorName     "Unknown"
    ModelName      "Unknown"
    HorizSync       28.0 - 33.0
    VertRefresh     43.0 - 72.0
    Option         "DPMS"
EndSection

Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    BusID          "131:0:0"
EndSection

Section "Screen"
    Identifier     "Screen0"
    Device         "Device0"
    #//Monitor        "Monitor0"
    #//DefaultDepth    24
    Option         "ConstantFrameRateHint" "True"
    Option         "UseDisplayDevice" "none"
    #//SubSection     "Display"
   #//     Depth       24
   # EndSubSection
EndSection
```   

### 3 重启 X 服务(需 sudo权限)
  首先，需要关闭 X 进程
  ``` 
  init 3
  ```
  然后可以用 ``` ps aux | grep X ``` 来检查有没有 残留的 /usr/bin/X 进程 ， 最好将 Xvnc 等进程也关闭掉。
  启动 X 进程
  ```
  sudo /usr/bin/X :0 &
  ```
  之前也试过通过  init 5 && startX 来启动 X ， 但似乎  sudo X 更好用些。 
  
  如果xorg.conf 的配置没有问题的话， 启动过程会一切正常，并可以看到一系列的 built-in extension 正常启动，以及 GLX , NV-GLX 正常Load ,会报一个 FATAL : Module nvidia_modeset not found , 但没什么影响。
  
## 检查和测试

### 4 简单测试（不需要显示图像）

```
  export DISPLAY=:0
  /WORK/app/osenv/ln1/usr/bin/glxgears
```
   ~~如果找不到 glxgears ，请用 /WORK/app/osenv/ln1/usr/bin/glxgears~~
   
   如果正常，这时候并没有图像输出，但会显示渲染 frames 的 FPS 数据。 可以用 ldd 命令查看 glxgears 调用的 libGL.so 和 libglx.so 库是哪个。

### 5 远程可视化使用GPU 
  
   [VNC 环境的使用参考](https://github.com/JiangLiNSCC/TH2-demos/blob/master/Use%20VNC%20.ipynb)

  在需要启动的GUI 程序前，通过 vglrun 启动即可。如
  /WORK/app/VirtualGL/bin/vglrun  /WORK/app/osenv/ln1/usr/bin/glxgears 
  
  可以通过 nvidia-smi  来查看现在用到了显卡的进程有哪些。
  
## 问题

  1. 加载某些环境变量会影响 vgl 的工作。
  
  如下例：
  
  ```
  source /WORK/app/osenv/ln1/set2.sh
  glxgears
  ```
  这时候会出错：
  ```
  Error: couldn't get an RGB, Double-buffered visual
  ```
  这个错误的原因是因为LD_LIBRARY_PATH 里没有 /usr/lib64 ; 导致 libGL 和 libGLX 库调用的是原来的系统库，而不是NVIDIA 驱动安装的版本。
  
  解决办法：
  ```
  export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH
  ```
  
## 通过测试的软件

  * Abaqus (system) 
  * ParaView (4.3.1-Linux-64bit)

  
  
  
  
