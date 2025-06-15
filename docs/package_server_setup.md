# 打包机API服务器配置指南

本文档介绍如何在打包机上配置API服务器，以支持HAP助手应用的包文件管理功能。

## 概述

HAP助手应用需要通过HTTP API与打包机通信，获取包文件列表和下载包文件。打包机需要运行一个简单的HTTP服务器来提供这些API接口。

## API接口规范

### 1. 健康检查接口

**接口地址**: `GET http://{打包机IP}:8080/api/health`

**响应示例**:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 2. 包文件列表接口

**接口地址**: `GET http://{打包机IP}:8080/api/packages`

**请求参数**:
- `path`: 包文件目录路径（如：`/Users/customer/harmony/haps/`）
- `extensions`: 文件扩展名过滤（如：`hap,app`）

**响应示例**:
```json
{
  "success": true,
  "message": "获取成功",
  "files": [
    {
      "name": "com.example.app_v1.0.0.hap",
      "path": "/Users/customer/harmony/haps/com.example.app_v1.0.0.hap",
      "size": 5242880,
      "createdTime": "2024-01-01T10:30:00Z"
    },
    {
      "name": "com.test.demo_v2.1.0.app",
      "path": "/Users/customer/harmony/haps/com.test.demo_v2.1.0.app",
      "size": 8388608,
      "createdTime": "2024-01-01T11:15:00Z"
    }
  ]
}
```

### 3. 文件下载接口

**接口地址**: `GET http://{打包机IP}:8080/api/download`

**请求参数**:
- `path`: 文件完整路径

**响应**: 直接返回文件内容（二进制流）

## Node.js 服务器实现示例

创建 `package-server.js` 文件：

```javascript
const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = 8080;

// 启用CORS
app.use(cors());
app.use(express.json());

// 健康检查接口
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString()
  });
});

// 获取包文件列表
app.get('/api/packages', (req, res) => {
  const { path: dirPath, extensions } = req.query;
  
  if (!dirPath) {
    return res.status(400).json({
      success: false,
      message: '缺少path参数'
    });
  }
  
  try {
    // 检查目录是否存在
    if (!fs.existsSync(dirPath)) {
      return res.status(404).json({
        success: false,
        message: '目录不存在'
      });
    }
    
    // 读取目录内容
    const files = fs.readdirSync(dirPath);
    const extList = extensions ? extensions.split(',').map(ext => `.${ext}`) : ['.hap', '.app'];
    
    const packageFiles = files
      .filter(file => {
        const ext = path.extname(file).toLowerCase();
        return extList.includes(ext);
      })
      .map(file => {
        const filePath = path.join(dirPath, file);
        const stats = fs.statSync(filePath);
        
        return {
          name: file,
          path: filePath,
          size: stats.size,
          createdTime: stats.birthtime.toISOString()
        };
      })
      .sort((a, b) => new Date(b.createdTime) - new Date(a.createdTime)); // 按创建时间倒序
    
    res.json({
      success: true,
      message: '获取成功',
      files: packageFiles
    });
    
  } catch (error) {
    console.error('获取包文件列表失败:', error);
    res.status(500).json({
      success: false,
      message: `获取文件列表失败: ${error.message}`
    });
  }
});

// 文件下载接口
app.get('/api/download', (req, res) => {
  const { path: filePath } = req.query;
  
  if (!filePath) {
    return res.status(400).json({
      success: false,
      message: '缺少path参数'
    });
  }
  
  try {
    // 检查文件是否存在
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({
        success: false,
        message: '文件不存在'
      });
    }
    
    // 设置响应头
    const fileName = path.basename(filePath);
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    res.setHeader('Content-Type', 'application/octet-stream');
    
    // 创建文件流并发送
    const fileStream = fs.createReadStream(filePath);
    fileStream.pipe(res);
    
  } catch (error) {
    console.error('文件下载失败:', error);
    res.status(500).json({
      success: false,
      message: `文件下载失败: ${error.message}`
    });
  }
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
  console.log(`包文件服务器已启动，监听端口 ${PORT}`);
  console.log(`健康检查: http://localhost:${PORT}/api/health`);
});
```

## 部署步骤

### 1. 安装Node.js

在打包机上安装Node.js（建议版本16+）：

**Windows**:
- 从 [Node.js官网](https://nodejs.org/) 下载并安装

**macOS**:
```bash
# 使用Homebrew安装
brew install node
```

**Linux**:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nodejs npm

# CentOS/RHEL
sudo yum install nodejs npm
```

### 2. 创建项目目录

```bash
mkdir hap-package-server
cd hap-package-server
```

### 3. 初始化项目

```bash
npm init -y
npm install express cors
```

### 4. 创建服务器文件

将上面的 `package-server.js` 代码保存到项目目录中。

### 5. 启动服务器

```bash
node package-server.js
```

### 6. 设置开机自启动（可选）

**Windows** (使用PM2):
```bash
npm install -g pm2
pm2 start package-server.js --name "hap-package-server"
pm2 startup
pm2 save
```

**Linux/macOS** (使用systemd):
创建 `/etc/systemd/system/hap-package-server.service`：
```ini
[Unit]
Description=HAP Package Server
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/path/to/hap-package-server
ExecStart=/usr/bin/node package-server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl enable hap-package-server
sudo systemctl start hap-package-server
```

## 防火墙配置

确保打包机的防火墙允许8080端口的入站连接：

**Windows**:
```cmd
netsh advfirewall firewall add rule name="HAP Package Server" dir=in action=allow protocol=TCP localport=8080
```

**Linux (iptables)**:
```bash
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

**Linux (firewalld)**:
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

## 测试验证

1. **健康检查**:
   ```bash
   curl http://打包机IP:8080/api/health
   ```

2. **获取包文件列表**:
   ```bash
   curl "http://打包机IP:8080/api/packages?path=/Users/customer/harmony/haps/&extensions=hap,app"
   ```

3. **在HAP助手中配置**:
   - 打开HAP助手应用
   - 进入"HAP安装"页面
   - 点击设置按钮
   - 输入打包机IP地址和HAP文件路径
   - 点击保存并刷新

## 故障排除

### 1. 连接超时
- 检查打包机IP地址是否正确
- 检查网络连接是否正常
- 检查防火墙设置
- 确认服务器是否正在运行

### 2. 文件列表为空
- 检查HAP文件路径是否正确
- 确认目录中是否有.hap或.app文件
- 检查目录权限

### 3. 下载失败
- 检查文件是否存在
- 确认文件权限
- 检查磁盘空间

## 安全建议

1. **网络安全**:
   - 仅在内网环境中使用
   - 考虑使用VPN或专用网络
   - 定期更新Node.js和依赖包

2. **访问控制**:
   - 可以添加API密钥验证
   - 限制访问IP范围
   - 使用HTTPS（生产环境）

3. **文件安全**:
   - 限制可访问的目录范围
   - 验证文件路径，防止目录遍历攻击
   - 定期清理临时文件