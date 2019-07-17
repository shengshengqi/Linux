# 操作系统实验2019.7
- 虚拟机安装和编译内核
  - 可以到官网下载免费版的VMware Workstation 15 Player，避免自己破解产生的奇怪错误
  - 新建虚拟机时最好设置4G内存
  - 如果编译内核出现奇怪错误，可以尝试扩大内存
  - 使用 make -j4或j8可以加快编译速度
- systemCall 系统调用部分代码解读
  - set_user_nice.v
    对于`set_user_nice`的详细注释
  - mycall.v
    系统调用添加的三个内容
  - about_set_user_nice.v
    关于`set_user_nice`的部分函数注释
- module 编译模块
  - 编译模块参考我的仓库中的OS-lab的内容
- pthread 管道通信&消息队列&共享内存
  - 涉及线程的程序启动时，要记得 -pthread 
  - pipeline.c 管道通信
  - queue.c 消息队列
  - receive.c sender.c share_memory.h 共享内存
    仅实现1次收发
- 文件系统 参考OS-lab 
  - 文件系统魔术用于标记文件，确定打开的文件正确。
- tips
  - 在你的ubuntu虚拟机中安装linux版的vscode，可提高写代码舒适度
