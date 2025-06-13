import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/app_provider.dart';

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
    return Container(
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
              Icons.cloud_upload_outlined,
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
              '支持 .hap 和 .app 格式',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileSize,
                  style: TextStyle(
                    color: Colors.grey.shade600,
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
              Container(
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
                      '请确保设备已连接并开启USB调试',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else if (provider.selectedDevice != null)
              Container(
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
                            '鸿蒙设备',
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
              )
            else
              Container(
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
              ),
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
            ? Theme.of(context).colorScheme.primary
            : null,
          foregroundColor: canInstall ? Colors.white : null,
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

  Future<void> _pickHapFile(BuildContext context, AppProvider provider) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['hap', 'app'],
        dialogTitle: '选择HAP文件',
      );

      if (result != null && result.files.single.path != null) {
        final hapPath = result.files.single.path!;
        provider.selectHapFile(hapPath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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