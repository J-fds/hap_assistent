import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class DeviceSelector extends StatelessWidget {
  const DeviceSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和刷新按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '连接的设备',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : () {
                      provider.refreshDevices();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('刷新'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 设备列表
              Expanded(
                child: _buildDeviceList(context, provider),
              ),
              
              const SizedBox(height: 24),
              
              // 连接说明
              _buildConnectionGuide(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceList(BuildContext context, AppProvider provider) {
    // 如果正在加载，显示加载指示器
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在扫描设备...'),
          ],
        ),
      );
    }
    
    // 如果工具未安装，显示提示
    if (!provider.isToolsInstalled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_outlined,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              '鸿蒙开发工具未安装',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '请先下载并安装鸿蒙开发工具',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // 如果设备列表为空，显示空状态
    if (provider.connectedDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smartphone_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '未发现设备',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '当前没有设备连接到电脑\n请确保设备已连接并开启开发者模式',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                '提示：hdc list targets 返回 [Empty]',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue[700],
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.refreshDevices(),
              icon: const Icon(Icons.refresh),
              label: const Text('重新扫描'),
            ),
          ],
        ),
      );
    }
    
    // 如果有选中的设备，只显示选中的设备
    if (provider.selectedDevice != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.smartphone,
              color: Colors.green,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '鸿蒙设备',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${provider.selectedDevice}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ],
        ),
      );
    }
    
    // 如果没有选中设备但有可用设备，显示提示
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            '请在设备管理中选择设备',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '发现 ${provider.connectedDevices.length} 个可用设备',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionGuide(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '连接设备指南',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGuideStep(context, '1', '在设备上打开"设置" > "系统和更新" > "开发人员选项"'),
            _buildGuideStep(context, '2', '开启"USB调试"和"仅充电模式下允许ADB调试"'),
            _buildGuideStep(context, '3', '使用USB数据线连接设备到电脑'),
            _buildGuideStep(context, '4', '在设备上允许USB调试授权'),
            _buildGuideStep(context, '5', '点击"刷新"按钮扫描设备'),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(BuildContext context, String step, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}