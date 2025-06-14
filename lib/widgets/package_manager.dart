import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class PackageManager extends StatefulWidget {
  const PackageManager({super.key});

  @override
  State<PackageManager> createState() => _PackageManagerState();
}

class _PackageManagerState extends State<PackageManager> {
  @override
  void initState() {
    super.initState();
    // 初始化时刷新包文件列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshPackageFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '包管理',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showSettingsDialog(context, provider),
                        icon: const Icon(Icons.settings),
                        label: const Text('设置'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: provider.isLoadingPackages
                            ? null
                            : () => provider.refreshPackageFiles(),
                        icon: provider.isLoadingPackages
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                        label: const Text('刷新'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 服务器信息
              _buildServerInfo(context, provider),
              const SizedBox(height: 16),
              
              // 包文件列表
              Expanded(
                child: _buildPackageList(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServerInfo(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.folder_shared,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '打包机共享文件夹',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '文件路径: ${provider.sharedFolderPath}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                '${provider.packageFiles.length} 个包',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageList(BuildContext context, AppProvider provider) {
    if (provider.isLoadingPackages) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在获取包文件列表...'),
          ],
        ),
      );
    }

    if (provider.packageFiles.isEmpty) {
      return _buildEmptyState(context, provider);
    }

    return ListView.builder(
      itemCount: provider.packageFiles.length,
      itemBuilder: (context, index) {
        final packageFile = provider.packageFiles[index];
        return _buildPackageItem(context, provider, packageFile);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无包文件',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '共享文件夹中没有找到 .hap 或 .app 文件',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.refreshPackageFiles(),
            icon: const Icon(Icons.refresh),
            label: const Text('重新扫描'),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageItem(BuildContext context, AppProvider provider, PackageFile packageFile) {
    final isInstalling = provider.installProgress.containsKey(packageFile.name);
    final installProgress = provider.installProgress[packageFile.name] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _installPackage(context, provider, packageFile),
        onDoubleTap: () => _installPackage(context, provider, packageFile),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 包类型图标
              CircleAvatar(
                backgroundColor: packageFile.type == 'hap' ? Colors.blue : Colors.green,
                child: Text(
                  packageFile.type.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // 包信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      packageFile.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(packageFile.createdTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.storage,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatFileSize(packageFile.size),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    // 安装进度条
                    if (isInstalling) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: installProgress,
                              backgroundColor: Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(installProgress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // 安装按钮
              if (!isInstalling)
                ElevatedButton.icon(
                  onPressed: provider.selectedDevice == null
                      ? null
                      : () => _installPackage(context, provider, packageFile),
                  icon: const Icon(Icons.install_mobile, size: 18),
                  label: const Text('安装'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    '安装中...',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _installPackage(BuildContext context, AppProvider provider, PackageFile packageFile) async {
    if (provider.selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先在"设备管理"页面选择要安装的设备'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await provider.installPackageFile(packageFile);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '${packageFile.name} 安装成功' : '${packageFile.name} 安装失败',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showSettingsDialog(BuildContext context, AppProvider provider) {
    final ipController = TextEditingController(text: provider.packageServerIp);
    final pathController = TextEditingController(text: provider.sharedFolderPath);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('包服务器设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: '打包机IP地址',
                hintText: '例如: 10.44.139.92',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                labelText: 'HAP文件路径',
                hintText: '例如: /Users/customer/harmony/haps/',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.setPackageServerConfig(
                ipController.text.trim(),
                pathController.text.trim(),
              );
              Navigator.of(context).pop();
              provider.refreshPackageFiles();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}