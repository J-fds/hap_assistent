import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';
import '../models/package_file.dart';
import '../services/network_hdc_service.dart';
import '../screens/home_screen.dart';

class HapInstaller extends StatelessWidget {
  const HapInstaller({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  'HAP包安装',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                
                // HAP文件选择区域
                _buildHapFileSelector(context, provider),
                const SizedBox(height: 16),
                
                // 目标设备选择
                _buildDeviceSelector(context, provider),
                const SizedBox(height: 24),
                
                // 安装按钮
                _buildInstallButton(context, provider),
                const SizedBox(height: 24),
                
                // 安装说明
                _buildInstallGuide(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHapFileSelector(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_present,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'HAP文件',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 智能选包开关
                InkWell(
                  onTap: () {
                    // 添加触觉反馈
                    HapticFeedback.lightImpact();
                    provider.setAutoSelectLatest(!provider.autoSelectLatest);
                  },
                  borderRadius: BorderRadius.circular(20),
                  splashColor: Colors.blue.withOpacity(0.1),
                  highlightColor: Colors.blue.withOpacity(0.05),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: provider.autoSelectLatest 
                          ? Colors.blue.shade50 
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: provider.autoSelectLatest 
                            ? Colors.blue.shade200 
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                      boxShadow: provider.autoSelectLatest ? [
                        BoxShadow(
                          color: Colors.blue.shade100,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            provider.autoSelectLatest 
                                ? Icons.auto_awesome 
                                : Icons.auto_awesome_outlined,
                            key: ValueKey(provider.autoSelectLatest),
                            size: 16,
                            color: provider.autoSelectLatest 
                                ? Colors.blue.shade600 
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '智能选包',
                          style: TextStyle(
                            color: provider.autoSelectLatest 
                                ? Colors.blue.shade700 
                                : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: provider.autoSelectLatest 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: provider.autoSelectLatest 
                                ? Colors.blue.shade600 
                                : Colors.grey.shade300,
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: provider.autoSelectLatest 
                                ? Alignment.centerRight 
                                : Alignment.centerLeft,
                            child: Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (provider.selectedHapPath == null)
              _buildFileDropZone(context, provider)
            else
              _buildSelectedFile(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildFileDropZone(BuildContext context, AppProvider provider) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: InkWell(
            onTap: () => _pickHapFile(context, provider),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_shared,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  '点击选择HAP文件',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '从共享文件夹选择 (.hap/.app)',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 本地文件选择按钮
        Center(
          child: TextButton.icon(
            onPressed: () => _pickFromLocalFiles(context, provider),
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('或从本地选择文件'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              textStyle: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFile(BuildContext context, AppProvider provider) {
    final file = File(provider.selectedHapPath!);
    final fileName = file.path.split('/').last;
    final fileSize = _formatFileSize(file.lengthSync());
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileSize,
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              provider.clearHapSelection();
            },
            icon: const Icon(Icons.close),
            tooltip: '清除选择',
          ),
          IconButton(
            onPressed: () => _pickHapFile(context, provider),
            icon: const Icon(Icons.edit),
            tooltip: '重新选择',
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smartphone,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '目标设备',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: provider.isLoading ? null : () {
                    provider.refreshDevices();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('刷新'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (provider.connectedDevices.isEmpty)
              _buildNoDeviceWarning(context)
            else
              _buildDeviceList(context, provider),
            
            const SizedBox(height: 12),
            
            // 网络设备选择提示
            _buildNetworkDeviceHint(context),

          ],
        ),
      ),
    );
  }

  Widget _buildInstallButton(BuildContext context, AppProvider provider) {
    final canInstall = provider.selectedHapPath != null && 
                      provider.selectedDevice != null && 
                      provider.isToolsInstalled &&
                      !provider.isLoading;
    
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: canInstall ? () => _installHap(context, provider) : null,
        icon: provider.isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.install_mobile),
        label: Text(
          provider.isLoading ? _getLoadingText(provider) : '安装HAP包',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canInstall 
            ? Colors.blue[600]
            : Colors.grey[300],
          foregroundColor: canInstall 
            ? Colors.white 
            : Colors.grey[600],
          elevation: canInstall ? 2 : 0,
          shadowColor: canInstall ? Colors.blue.withOpacity(0.3) : null,
        ),
      ),
    );
  }

  Widget _buildInstallGuide(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '安装提示',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTip('确保设备已开启开发者模式和USB调试'),
            _buildTip('首次安装可能需要在设备上确认安装权限'),
            _buildTip('安装过程中请保持设备连接'),
            _buildTip('如果安装失败，请检查HAP包是否完整'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 选择HAP文件 - 默认打开共享文件夹
  Future<void> _pickHapFile(BuildContext context, AppProvider provider) async {
    await _pickFromSharedFolder(context, provider);
  }

  Future<void> _pickFromSharedFolder(BuildContext context, AppProvider provider) async {
    // 显示加载对话框
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在连接打包机...'),
            ],
          ),
        ),
      );
    }
    
    try {
      // 刷新包文件列表
      await provider.refreshPackageFiles();
      
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (provider.packageFiles.isEmpty) {
        if (context.mounted) {
          _showConnectionErrorDialog(context, provider);
        }
        return;
      }
    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        _showConnectionErrorDialog(context, provider);
      }
      return;
    }

    // 显示共享文件夹中的文件列表
    if (context.mounted) {
      final selectedFile = await showDialog<PackageFile>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择HAP文件'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: provider.packageFiles.length,
              itemBuilder: (context, index) {
                final file = provider.packageFiles[index];
                return ListTile(
                  leading: Icon(
                    file.type == 'hap' ? Icons.android : Icons.apps,
                    color: Colors.blue,
                  ),
                  title: Text(file.name),
                  subtitle: Text(
                    '${_formatFileSize(file.size)} • ${_formatDateTime(file.createdTime)}',
                  ),
                  onTap: () => Navigator.of(context).pop(file),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        ),
      );

      if (selectedFile != null) {
        provider.selectHapFile(selectedFile.path);
      }
    }
  }

  /// 从本地文件选择
  Future<void> _pickFromLocalFiles(BuildContext context, AppProvider provider) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['hap', 'app'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          provider.selectHapFile(file.path!);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择本地文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 显示连接错误对话框
  void _showConnectionErrorDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('连接失败'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('无法连接到打包机或共享文件夹为空'),
            const SizedBox(height: 12),
            Text('打包机IP: ${provider.packageServerIp}'),
            Text('文件路径: ${provider.sharedFolderPath}'),
            const SizedBox(height: 12),
            const Text(
              '请检查：\n• 打包机IP地址是否正确\n• 网络连接是否正常\n• 共享文件夹中是否有HAP/APP文件\n• 打包机API服务是否启动',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 打开设置对话框
              _showSettingsDialog(context, provider);
            },
            child: const Text('设置'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 重试连接
              _pickFromSharedFolder(context, provider);
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 显示设置对话框
  void _showSettingsDialog(BuildContext context, AppProvider provider) {
    final ipController = TextEditingController(text: provider.packageServerIp);
    final pathController = TextEditingController(text: provider.sharedFolderPath);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('打包机设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: '打包机IP地址',
                hintText: '例如: 192.168.1.100',
                prefixIcon: Icon(Icons.computer),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                labelText: 'HAP文件路径',
                hintText: '例如: /Users/customer/harmony/haps/',
                prefixIcon: Icon(Icons.folder),
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
              provider.setPackageServerIp(ipController.text.trim());
              provider.setSharedFolderPath(pathController.text.trim());
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('设置已保存'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  String _getLoadingText(AppProvider provider) {
    // 根据状态消息判断当前操作类型
    if (provider.statusMessage.contains('扫描') || provider.statusMessage.contains('刷新')) {
      return '刷新中...';
    } else if (provider.statusMessage.contains('安装')) {
      return '正在安装...';
    } else if (provider.statusMessage.contains('下载')) {
      return '下载中...';
    } else {
      return '处理中...';
    }
  }

  Future<void> _installHap(BuildContext context, AppProvider provider) async {
    final success = await provider.installHap();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'HAP包安装成功！' : 'HAP包安装失败，请查看日志了解详情',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          action: success ? null : SnackBarAction(
            label: '查看日志',
            onPressed: () {
              // 这里可以切换到日志标签页
            },
          ),
        ),
      );
    }
  }

  Widget _buildNoDeviceWarning(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.orange.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            '未发现连接的设备',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '请确保设备已连接并开启USB调试，或使用网络设备功能',
            style: TextStyle(
              color: Colors.orange.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeviceList(BuildContext context, AppProvider provider) {
    if (provider.selectedDevice != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.smartphone,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '已选择设备',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${provider.selectedDevice}',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              Icons.touch_app,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              '请在设备管理中选择目标设备',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '发现 ${provider.connectedDevices.length} 个可用设备',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }
  
  Widget _buildNetworkDeviceHint(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // 如果已经有设备连接，则不显示网络设备提示
        if (provider.connectedDevices.isNotEmpty) {
          return const SizedBox.shrink();
        }
        
        return InkWell(
          onTap: () {
            // 切换到设备管理标签页
            // 查找父级的 HomeScreen 并切换到设备管理标签页
            final homeScreenState = context.findAncestorStateOfType<State<HomeScreen>>();
            if (homeScreenState != null && homeScreenState is State<HomeScreen>) {
              // 调用切换方法
              (homeScreenState as dynamic).switchToDeviceTab();
            } else {
              // 如果找不到HomeScreen，显示提示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请切换到设备管理标签页进行设备连接'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              border: Border.all(color: Colors.purple.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi,
                  color: Colors.purple.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '也可以使用"网络设备"功能进行无线连接和安装',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.purple.shade600,
                  size: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}