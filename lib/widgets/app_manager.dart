import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AppManager extends StatelessWidget {
  const AppManager({super.key});

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
                // 标题和刷新按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '应用管理',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    ElevatedButton.icon(
                      onPressed: provider.isLoading || provider.selectedDevice == null 
                        ? null 
                        : () {
                            provider.refreshInstalledApps();
                          },
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 设备信息
                _buildDeviceInfo(context, provider),
                const SizedBox(height: 16),
                
                // 应用列表
                _buildAppList(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceInfo(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.smartphone,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前设备',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.selectedDevice ?? '未选择设备',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (provider.selectedDevice != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  '${provider.installedApps.length} 个应用',
                  style: TextStyle(
                    color: Colors.green.shade700,
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

  Widget _buildAppList(BuildContext context, AppProvider provider) {
    if (provider.selectedDevice == null) {
      return _buildNoDeviceState(context);
    }
    
    if (provider.installedApps.isEmpty) {
      return _buildEmptyState(context, provider);
    }
    
    return _buildAppListView(context, provider);
  }

  Widget _buildNoDeviceState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smartphone_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '请先选择设备',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在"设备管理"页面选择要管理的设备',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            provider.isLoading ? '正在获取应用列表...' : '暂无已安装的应用',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          if (!provider.isLoading) ...[
            const SizedBox(height: 8),
            Text(
              '设备上可能没有安装任何应用，或者需要刷新列表',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                provider.refreshInstalledApps();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('刷新列表'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppListView(BuildContext context, AppProvider provider) {
    return ListView.builder(
      itemCount: provider.installedApps.length,
      itemBuilder: (context, index) {
        final app = provider.installedApps[index];
        return _buildAppItem(context, provider, app, index);
      },
    );
  }

  Widget _buildAppItem(BuildContext context, AppProvider provider, String app, int index) {
    // 解析应用信息（这里需要根据实际的hdc输出格式进行调整）
    final appInfo = _parseAppInfo(app);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAppColor(index),
          child: Text(
            appInfo['name']?.substring(0, 1).toUpperCase() ?? 'A',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          appInfo['name'] ?? app,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (appInfo['package'] != null)
              Text(
                '包名: ${appInfo['package']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            if (appInfo['version'] != null)
              Text(
                '版本: ${appInfo['version']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'uninstall') {
              _showUninstallDialog(context, provider, appInfo['package'] ?? app);
            } else if (value == 'info') {
              _showAppInfo(context, appInfo);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('应用信息'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'uninstall',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('卸载应用', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _parseAppInfo(String appString) {
    // 这里需要根据实际的hdc命令输出格式进行解析
    // 目前提供一个基础的解析示例
    final parts = appString.split(' ');
    return {
      'name': parts.isNotEmpty ? parts[0] : appString,
      'package': appString,
      'version': '',
    };
  }

  Color _getAppColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  void _showUninstallDialog(BuildContext context, AppProvider provider, String packageName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认卸载'),
        content: Text(
          '确定要卸载应用 "$packageName" 吗？\n\n'
          '此操作不可撤销，应用数据也将被删除。',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await provider.uninstallApp(packageName);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '应用卸载成功' : '应用卸载失败，请查看日志了解详情',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('卸载'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context, Map<String, String> appInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('应用信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('应用名称', appInfo['name'] ?? '未知'),
            _buildInfoRow('包名', appInfo['package'] ?? '未知'),
            _buildInfoRow('版本', appInfo['version'] ?? '未知'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}