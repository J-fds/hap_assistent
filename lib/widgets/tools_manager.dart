import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ToolsManager extends StatefulWidget {
  const ToolsManager({super.key});

  @override
  State<ToolsManager> createState() => _ToolsManagerState();
}

class _ToolsManagerState extends State<ToolsManager> {
  bool _isInstalling = false;
  double _progress = 0.0;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.build_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('鸿蒙开发工具'),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 工具状态
                  _buildToolStatus(context, provider),
                  const SizedBox(height: 16),
                  
                  // 工具说明
                  _buildToolDescription(context),
                  const SizedBox(height: 16),
                  
                  // 下载进度
                  if (_isInstalling || provider.downloadProgress > 0)
                    _buildDownloadProgress(context, provider),
                  
                  // 安装说明
                  if (!provider.isToolsInstalled && !_isInstalling)
                    _buildInstallInstructions(context),
                ],
              ),
            ),
          ),
          actions: _buildActions(context, provider),
        );
      },
    );
  }

  Widget _buildToolStatus(BuildContext context, AppProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: provider.isToolsInstalled 
          ? Colors.green.shade50 
          : Colors.orange.shade50,
        border: Border.all(
          color: provider.isToolsInstalled 
            ? Colors.green.shade200 
            : Colors.orange.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            provider.isToolsInstalled 
              ? Icons.check_circle 
              : Icons.warning_amber,
            color: provider.isToolsInstalled 
              ? Colors.green.shade600 
              : Colors.orange.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.isToolsInstalled ? '工具已安装' : '需要安装工具',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: provider.isToolsInstalled 
                      ? Colors.green.shade700 
                      : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.isToolsInstalled 
                    ? '鸿蒙开发工具已就绪，可以开始安装HAP包'
                    : '需要下载鸿蒙开发工具才能进行HAP包安装',
                  style: TextStyle(
                    fontSize: 12,
                    color: provider.isToolsInstalled 
                      ? Colors.green.shade600 
                      : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolDescription(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  '工具说明',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '鸿蒙开发工具包含以下组件：',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 4),
            _buildToolItem('hdc', 'HarmonyOS Device Connector - 设备连接工具'),
            _buildToolItem('hap', 'HAP包管理工具'),
            _buildToolItem('其他', '应用调试和管理相关工具'),
          ],
        ),
      ),
    );
  }

  Widget _buildToolItem(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                ),
                children: [
                  TextSpan(
                    text: '$name: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress(BuildContext context, AppProvider provider) {
    final progress = _isInstalling ? _progress : provider.downloadProgress;
    final message = _isInstalling ? _statusMessage : provider.statusMessage;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              '下载进度',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInstallInstructions(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  '安装说明',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInstruction('工具将自动下载到应用数据目录'),
            _buildInstruction('首次下载可能需要几分钟时间'),
            _buildInstruction('请确保网络连接正常'),
            _buildInstruction('下载完成后工具将自动配置'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String instruction) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, AppProvider provider) {
    if (provider.isToolsInstalled) {
      return [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('关闭'),
        ),
      ];
    }

    if (_isInstalling || provider.isLoading) {
      return [
        TextButton(
          onPressed: null,
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: null,
          child: const Text('安装中...'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('取消'),
      ),
      ElevatedButton(
        onPressed: () {
          _startInstallation(provider);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        child: const Text('开始安装'),
      ),
    ];
  }

  Future<void> _startInstallation(AppProvider provider) async {
    setState(() {
      _isInstalling = true;
      _progress = 0.0;
      _statusMessage = '准备下载...';
    });

    try {
      final success = await provider.downloadAndInstallTools();
      
      if (success) {
        setState(() {
          _progress = 1.0;
          _statusMessage = '安装完成';
        });
        
        // 延迟一下再关闭对话框
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('鸿蒙开发工具安装成功！'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _statusMessage = '安装失败';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('工具安装失败，请检查网络连接后重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = '安装出错: $e';
      });
    } finally {
      setState(() {
        _isInstalling = false;
      });
    }
  }
}