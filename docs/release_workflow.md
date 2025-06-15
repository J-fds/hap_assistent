# 自动化发布流程说明

## 概述

本项目已配置自动化的GitHub Actions工作流，用于构建和发布应用程序。工作流支持两种触发方式，避免了每次代码提交都进行打包的问题。

## 触发方式

### 1. 标签推送触发（推荐）

当推送以 `v` 开头的标签时，会自动触发构建和发布流程：

```bash
# 创建并推送标签
git tag v1.0.0
git push origin v1.0.0
```

### 2. 手动触发

在GitHub仓库的Actions页面，可以手动触发工作流：

1. 进入仓库的 **Actions** 页面
2. 选择 `Build Windows` 或 `Build macOS` 工作流
3. 点击 **Run workflow** 按钮
4. 选择是否创建Release：
   - `true`：构建完成后自动创建Release
   - `false`：仅构建，不创建Release

## 工作流特性

### 触发条件优化
- ✅ **仅在推送标签时自动触发**
- ✅ **支持手动触发**
- ❌ **不再因普通代码推送触发**
- ❌ **不再因Pull Request触发**

### 自动化Release
- 自动创建GitHub Release
- 自动上传构建产物
- 自动生成Release说明
- 支持多平台同时发布

## 构建产物

### Windows版本
1. **便携版** (`hap_assistant_windows_portable_*.tar.gz`)
   - 包含完整运行环境
   - 解压即用，无需安装

2. **精简版** (`hap_assistant_windows_single_*.tar.gz`)
   - 仅包含核心文件
   - 体积更小

### macOS版本
- **DMG安装包** (`HAP-Assistant-macOS.dmg`)
  - 标准macOS安装格式
  - 拖拽安装

## 版本管理

### 标签命名规范
建议使用语义化版本号：
- `v1.0.0` - 主要版本
- `v1.1.0` - 次要版本
- `v1.1.1` - 补丁版本
- `v1.0.0-beta.1` - 预发布版本

### 手动触发版本
手动触发时会自动生成基于时间戳的版本号：
- 格式：`vYYYYMMDD-HHMMSS`
- 示例：`v20241201-143022`

## 使用建议

### 开发阶段
- 正常提交代码到main分支
- 不会触发自动构建
- 可使用手动触发进行测试

### 发布阶段
1. 确保代码已合并到main分支
2. 创建并推送版本标签
3. 自动触发构建和发布
4. 在GitHub Releases页面查看发布结果

### 紧急发布
- 使用手动触发功能
- 选择创建Release
- 系统自动生成时间戳版本号

## 故障排除

### 构建失败
1. 检查Actions页面的错误日志
2. 确认Flutter版本兼容性
3. 检查依赖项是否正确安装

### Release创建失败
1. 确认GITHUB_TOKEN权限
2. 检查标签名称格式
3. 确认文件路径正确

### 手动触发无响应
1. 检查工作流文件语法
2. 确认分支权限设置
3. 查看Actions页面状态

## 配置文件

相关配置文件位置：
- `.github/workflows/build-windows.yml` - Windows构建流程
- `.github/workflows/build-macos.yml` - macOS构建流程

如需修改构建配置，请编辑对应的工作流文件。