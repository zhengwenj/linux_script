# Linux 系统管理与优化脚本集合

这个仓库包含了一系列用于Linux系统管理、优化和常用服务安装的Shell脚本。这些脚本旨在简化Linux系统的日常管理任务，提高工作效率。

## 特点

- 🔧 **简化复杂任务**：将复杂的系统管理任务自动化
- 🌍 **多语言支持**：大部分脚本支持中英文双语界面
- 🔒 **安全可靠**：脚本执行前会进行必要的系统检查和确认
- 📊 **详细反馈**：提供清晰的执行过程和结果反馈
- 🛠️ **高度定制**：提供多种配置选项以适应不同需求

## 可用脚本

| 脚本名称 | 描述 | 目录 |
|---------|------|------|
| [Nginx 自动安装脚本](nginx_install/README.md) | 一键安装、配置Nginx，支持多实例管理和HTTPS配置 | [nginx_install](nginx_install/) |
| *(计划添加更多脚本)* | | |

## 使用方法

每个脚本都有其独立的文档和使用说明。点击上表中的脚本名称可以查看详细信息。

### 通用使用步骤

1. 克隆仓库到本地：

   #### 从GitHub克隆（国际用户）：

   ```bash
   git clone https://github.com/zhengwenj/linux_script.git
   cd linux_script
   ```

   #### 从Gitee克隆（国内用户）：

   ```bash
   git clone https://gitee.com/zhengwenj/linux_script.git
   cd linux_script
   ```

2. 进入相应脚本目录：
   ```bash
   cd 脚本目录名
   ```

3. 赋予脚本执行权限：
   ```bash
   chmod +x 脚本名.sh
   ```

4. 执行脚本：
   ```bash
   sudo ./脚本名.sh
   ```

## 系统要求

- 大多数脚本兼容主流Linux发行版（Debian、Ubuntu、CentOS、RHEL等）
- 需要root或sudo权限
- 部分脚本可能需要特定的系统工具，将在执行时提示安装

## 贡献指南

欢迎为这个仓库贡献代码、提出改进建议或报告问题。贡献步骤：

1. Fork 这个仓库
2. 创建你的特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交你的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开一个 Pull Request

## 许可证

本项目采用 [MIT License](LICENSE) 许可证。

## 免责声明

这些脚本仅供学习和参考使用。请在生产环境中谨慎使用，并在执行前备份重要数据。作者不对因使用这些脚本可能导致的任何损失负责。
