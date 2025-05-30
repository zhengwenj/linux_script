# Nginx 自动安装脚本

这是一个功能强大的Nginx自动安装脚本，支持中英文双语界面，可以自动检测系统环境、管理多个Nginx实例、配置HTTPS、设置随机可用端口等功能。

## 功能特点

- 🌍 **双语支持**：中文和英文界面自由切换
- 🔍 **多实例检测**：自动检测系统中已安装的所有Nginx实例
- 🚀 **灵活安装**：支持安装最新稳定版或指定任意版本
- 🔒 **HTTPS配置**：一键配置HTTPS（自签名证书）
- 🔌 **智能端口分配**：自动查找可用端口，避免端口冲突
- 🔄 **共存模式**：可与现有Nginx实例共存
- 🛠️ **自定义路径**：支持自定义安装路径
- 🚦 **开机自启**：可配置为开机自动启动
- 📊 **状态监控**：安装完成后显示详细的端口和进程信息

## 快速安装

### 方法1：直接下载并执行

#### GitHub下载（国际用户）：

```bash
wget -O nginx_install.sh https://raw.githubusercontent.com/zhengwenj/linux_script/main/nginx_install/nginx_install.sh
chmod +x nginx_install.sh
sudo ./nginx_install.sh
```

#### Gitee下载（国内用户）：

```bash
wget -O nginx_install.sh https://gitee.com/zhengwenj/linux_script/raw/main/nginx_install/nginx_install.sh
chmod +x nginx_install.sh
sudo ./nginx_install.sh
```

### 方法2：克隆仓库后执行

#### GitHub下载（国际用户）：

```bash
git clone https://github.com/zhengwenj/linux_script.git
cd linux_script/nginx_install
chmod +x nginx_install.sh
sudo ./nginx_install.sh
```

#### Gitee下载（国内用户）：

```bash
git clone https://gitee.com/zhengwenj/linux_script.git
cd linux_script/nginx_install
chmod +x nginx_install.sh
sudo ./nginx_install.sh
```

## 使用指南

1. **语言选择**：脚本启动后首先会提示选择语言（中文/英文）
2. **检测环境**：自动检测系统环境和已安装的Nginx实例
3. **版本选择**：可以选择安装最新稳定版或指定特定版本
   - 直接输入版本号（如`1.26.3`）即可安装指定版本
4. **安装路径**：可以使用默认路径或自定义安装路径
5. **HTTPS配置**：选择是否配置HTTPS支持
6. **端口配置**：可以手动指定端口或使用自动分配的随机可用端口
7. **开机自启**：选择是否将Nginx配置为开机自启动
8. **安装确认**：确认所有配置后开始安装
9. **启动服务**：安装完成后可选择立即启动Nginx服务

## 安装文件位置

- **下载的安装包**：位于临时目录中（通常为`/tmp/tmp.XXXXXXXX/nginx-版本号.tar.gz`）
- **解压后的源码**：位于临时目录中（通常为`/tmp/tmp.XXXXXXXX/nginx-版本号/`）
- **安装后的Nginx**：位于指定的安装路径（默认为`/usr/local/nginx`或自定义路径）

## 主要配置文件

- **Nginx配置文件**：`安装路径/conf/nginx.conf`
- **HTTPS证书**：`安装路径/conf/ssl/nginx.crt`（如果配置了HTTPS）
- **HTTPS私钥**：`安装路径/conf/ssl/nginx.key`（如果配置了HTTPS）
- **PID文件**：`安装路径/logs/nginx.pid`

## 管理命令

如果系统使用systemd：

```bash
sudo systemctl start nginx    # 启动Nginx
sudo systemctl stop nginx     # 停止Nginx
sudo systemctl restart nginx  # 重启Nginx
sudo systemctl status nginx   # 查看状态
```

如果系统未使用systemd，脚本会创建一个控制脚本：

```bash
sudo nginx-ctl start          # 启动Nginx
sudo nginx-ctl stop           # 停止Nginx
sudo nginx-ctl reload         # 重载配置
sudo nginx-ctl restart        # 重启Nginx
sudo nginx-ctl status         # 查看状态
```

## 卸载方法

脚本本身提供了卸载功能，重新运行脚本并选择卸载选项即可。

## 常见问题

1. **端口冲突**：如果出现端口冲突，脚本会自动提示并允许重新选择端口或使用随机可用端口
2. **多个Nginx实例**：脚本可以检测并管理多个Nginx实例，可以选择卸载指定实例或全部实例
3. **权限问题**：请确保使用sudo或root权限运行脚本

## 系统要求

- 支持的操作系统：大多数Linux发行版（Debian、Ubuntu、CentOS、RHEL等）
- 需要的依赖：wget、curl、gcc、make、openssl、pcre、zlib（脚本会自动检测并提示安装）
- 权限要求：需要root权限或sudo权限 