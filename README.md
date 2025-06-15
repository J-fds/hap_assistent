# 鸿蒙HAP安装助手

一个用于安装和管理HarmonyOS HAP应用包的桌面工具。

## 功能特性

- 🚀 **HAP文件安装** - 支持安装HarmonyOS应用包到设备
- 📱 **设备管理** - 自动检测和管理连接的HarmonyOS设备
- 🔧 **工具集成** - 集成HDC等开发工具
- 📋 **日志查看** - 实时查看安装过程和设备日志
- 🎨 **现代界面** - 简洁美观的用户界面

## 支持平台

- ✅ Windows 10/11 (x64)
- ✅ macOS 10.14+

## 安装方法

### Windows

1. 从 [Releases](https://github.com/your-username/hap_assistant/releases) 页面下载最新的 `HAP_Assistant_Setup.exe`
2. 以管理员权限运行安装程序
3. 按照安装向导完成安装

### macOS

1. 从 [Releases](https://github.com/your-username/hap_assistant/releases) 页面下载 `.dmg` 文件
2. 双击打开并将应用拖拽到应用程序文件夹


## 开发环境

### 环境要求

- Flutter 3.19.6+
- Dart 3.3.0+
- 对应平台的开发工具链

### 本地开发

```bash
# 克隆项目
git clone https://github.com/your-username/hap_assistant.git
cd hap_assistant

# 安装依赖
flutter pub get

# 启用桌面平台支持
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop

# 运行应用
flutter run -d windows  # Windows
flutter run -d macos    # macOS
```

### 构建发布版本

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## CI/CD

项目使用 GitHub Actions 进行自动化构建和发布：

### 工作流

1. **CI** (`.github/workflows/ci.yml`)
   - 代码分析和测试
   - 多平台构建检查
   - 每次推送和PR时触发

2. **Windows构建** (`.github/workflows/build-windows.yml`)
   - 自动构建Windows便携版和精简版
   - 生成可执行文件包
   - 标签推送时自动发布Release

3. **macOS构建** (`.github/workflows/build-macos.yml`)
   - 自动构建macOS应用
   - 生成DMG安装包
   - 标签推送时自动发布Release

### 发布流程

1. 创建新的版本标签：
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. GitHub Actions会自动：
   - 构建Windows安装包
   - 创建GitHub Release
   - 上传安装文件

## 项目结构

```
hap_assistant/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── providers/             # 状态管理
│   ├── screens/               # 页面组件
│   ├── services/              # 业务逻辑
│   └── widgets/               # UI组件
├── assets/
│   └── tools/                 # 工具文件
├── macos/                     # macOS平台配置
├── windows/                   # Windows平台配置
├── .github/
│   └── workflows/             # GitHub Actions工作流
└── app_icon_base.svg          # 应用图标源文件
```

## 技术栈

- **框架**: Flutter 3.19.6
- **状态管理**: Provider
- **平台支持**: Windows, macOS, Linux
- **CI/CD**: GitHub Actions
- **安装包**: NSIS (Windows)

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 更新日志

### v1.0.0
- ✨ 初始版本发布
- 🎨 简化的应用图标设计
- 🚀 HAP文件安装功能
- 📦 Windows自动安装包构建
- 🔧 集成HDC工具支持

## 支持

如果您遇到问题或有建议，请：

1. 查看 [Issues](https://github.com/your-username/hap_assistant/issues)
2. 创建新的 Issue
3. 联系开发团队

---

**注意**: 请确保您的设备已启用开发者模式并正确连接，以便使用HAP安装功能。
**windows**： windows上运行时可能会报错
下载后安装
https://aka.ms/vs/17/release/vc_redist.x64.exe
