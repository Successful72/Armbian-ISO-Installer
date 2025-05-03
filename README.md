# Armbian-ISO-Installer

## 关于
一个基于Debian Live系统的Img镜像安装器。采用github action构建，可在x86-64设备上快速安装Armbian系统。 

## 使用方式
1. 虚拟机使用：各种虚拟机直接选择iso即可
2. 物理机使用：建议将iso放入ventoy的U盘中

6. 具体的操作方法:在安装器所在系统里输入 `ddd` 命令方可调出安装菜单，后按照提示操作即可。
![localhost lan - VMware ESXi 2025-03-20 10-14-45](https://github.com/user-attachments/assets/ddae80a0-9ff5-4d63-83b5-1f49da18b008)

## ISO的制作流程
1. 首先构建一个debian live系统 该系统带EFI引导。
2. 在该系统内融入目标img镜像和自定义dd写盘脚本。一起打包到filesystem.squashfs文件系统中。该过程包含压缩,保证最终的镜像体积。
3. 最后将新的squashfs文件和相关文件一起打包为ISO

## 说明
本项目也是基于开源项目[debian-live](https://github.com/dpowers86/debian-live)制作.因此我的代码也是全程开源 MIT协议不变。

## 鸣谢
- https://github.com/wukongdaily/armbian-installer
- https://willhaley.com/blog/custom-debian-live-environment/
- https://github.com/dpowers86/debian-live
