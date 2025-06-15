# 共享文件夹连接说明

本文档说明HAP助手在不同操作系统上连接共享文件夹的方式和注意事项。

## 连接方式对比

### Windows系统

#### UNC路径格式
```
\\IP地址\共享文件夹名\路径
例如: \\192.168.1.100\harmony\haps\
```

#### 特点
- 直接使用UNC路径访问网络共享
- 支持映射网络驱动器
- 可以直接在文件资源管理器中访问
- 需要网络凭据认证（如果共享文件夹有密码保护）

#### 连接步骤
1. 确保打包机的共享文件夹已启用
2. 在HAP助手中设置正确的IP地址
3. 设置共享文件夹路径（如：`/harmony/haps/`）
4. 应用会自动转换为Windows UNC格式

### macOS系统

#### SMB协议格式
```
smb://IP地址/共享文件夹名/路径
例如: smb://192.168.1.100/harmony/haps/
```

#### 特点
- 使用SMB/CIFS协议连接
- 需要先挂载到本地文件系统
- 挂载点通常在 `/Volumes/` 目录下
- 支持Finder中的"连接服务器"功能

#### 连接步骤
1. 确保打包机支持SMB协议
2. 在HAP助手中设置正确的IP地址
3. 设置共享文件夹路径（如：`/harmony/haps/`）
4. 系统可能提示输入网络凭据
5. 成功后文件夹会出现在Finder侧边栏

### Linux系统

#### CIFS/SMB格式
```
//IP地址/共享文件夹名/路径
例如: //192.168.1.100/harmony/haps/
```

#### 特点
- 使用CIFS/SMB协议
- 需要手动挂载或使用自动挂载
- 挂载点通常在 `/mnt/` 或 `/media/` 目录下
- 可能需要安装 `cifs-utils` 包

## 应用中的实现

### 自动路径转换

应用会根据当前操作系统自动转换路径格式：

```dart
String getSharedFolderFullPath() {
  if (Platform.isWindows) {
    // Windows: \\IP\共享文件夹名\路径
    if (_sharedFolderPath.startsWith('/')) {
      String windowsPath = _sharedFolderPath.replaceAll('/', '\\');
      return '\\\\$_packageServerIp$windowsPath';
    } else {
      return '\\\\$_packageServerIp\\harmony\\haps\\';
    }
  } else if (Platform.isMacOS) {
    // macOS: smb://IP/共享文件夹名/路径
    if (_sharedFolderPath.startsWith('/')) {
      return 'smb://$_packageServerIp$_sharedFolderPath';
    } else {
      return 'smb://$_packageServerIp/harmony/haps/';
    }
  } else {
    // Linux: //IP/共享文件夹名/路径
    if (_sharedFolderPath.startsWith('/')) {
      return '//$_packageServerIp$_sharedFolderPath';
    } else {
      return '//$_packageServerIp/harmony/haps/';
    }
  }
}
```

### 本地挂载路径

对于需要直接文件操作的场景，应用提供本地挂载路径：

```dart
String getLocalMountPath() {
  if (Platform.isWindows) {
    // Windows可以直接使用UNC路径
    return getSharedFolderFullPath();
  } else if (Platform.isMacOS) {
    // macOS挂载点通常在/Volumes/下
    return '/Volumes/harmony/haps/';
  } else {
    // Linux挂载点
    return '/mnt/harmony/haps/';
  }
}
```

## 常见问题和解决方案

### Windows

**问题**: 无法访问UNC路径
- **解决**: 检查网络连接和防火墙设置
- **解决**: 确保SMB服务已启用
- **解决**: 尝试在文件资源管理器中手动访问路径

**问题**: 需要输入凭据
- **解决**: 在Windows凭据管理器中添加网络凭据
- **解决**: 使用"记住我的凭据"选项

### macOS

**问题**: SMB连接失败
- **解决**: 检查SMB协议版本兼容性
- **解决**: 在系统偏好设置中检查网络设置
- **解决**: 尝试使用Finder的"连接服务器"功能测试

**问题**: 挂载点不存在
- **解决**: 手动创建挂载点目录
- **解决**: 检查权限设置

### 通用问题

**问题**: IP地址无法访问
- **解决**: 使用ping命令测试网络连通性
- **解决**: 检查IP地址是否正确
- **解决**: 确认打包机和客户端在同一网络

**问题**: 共享文件夹为空
- **解决**: 确认HAP文件已放置在正确目录
- **解决**: 检查文件权限和共享权限
- **解决**: 确认文件扩展名为.hap或.app

## 最佳实践

1. **统一路径格式**: 在设置中使用Unix风格路径（以/开头），应用会自动转换
2. **网络凭据**: 提前配置好网络凭据，避免每次连接都需要输入
3. **防火墙设置**: 确保相关端口（SMB: 445, 139）未被阻止
4. **定期测试**: 定期测试网络连接，确保共享文件夹可访问
5. **备用方案**: 准备本地文件选择作为备用方案

## 技术细节

### 支持的协议
- **SMB/CIFS**: 主要协议，跨平台兼容性好
- **NFS**: Linux环境下的替代方案
- **FTP/SFTP**: 可作为备用传输方式

### 安全考虑
- 使用加密连接（SMB 3.0+）
- 避免在代码中硬编码凭据
- 定期更新网络凭据
- 限制共享文件夹的访问权限

### 性能优化
- 使用本地缓存减少网络访问
- 实现连接池复用网络连接
- 添加超时和重试机制
- 压缩传输数据减少带宽使用