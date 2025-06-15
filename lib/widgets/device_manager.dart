import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/network_hdc_service.dart';

class DeviceManager extends StatelessWidget {
  const DeviceManager({super.key});

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
                // 标题和操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '设备管理',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : () {
                            _showAddNetworkDeviceDialog(context, provider);
                          },
                          icon: const Icon(Icons.wifi),
                          label: const Text('添加网络设备'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : () {
                            provider.refreshDevices();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('刷新'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 设备列表
                _buildDeviceList(context, provider),
                
                const SizedBox(height: 16),
                
                // 连接说明
                _buildConnectionGuide(context),
              ],
            ),
          ),
      );
    },
    );
  }

  Widget _buildDeviceList(BuildContext context, AppProvider provider) {
    // 创建一个容器来包装设备列表区域，添加边框样式
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
      ),
      child: _buildDeviceContent(context, provider),
    );
  }

  Widget _buildDeviceContent(BuildContext context, AppProvider provider) {
    // 如果正在加载，显示加载指示器
    if (provider.isLoading) {
      return Container(
        height: 230,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                '正在扫描设备...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 如果工具未安装，显示提示
    if (!provider.isToolsInstalled) {
      return Container(
        height: 200,
        child: Center(
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
        ),
      );
    }
    
    // 如果设备列表为空，显示空状态
    if (provider.connectedDevices.isEmpty) {
      return Container(
        height: 230,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.smartphone_outlined,
                  size: 48,
                  color: const Color.fromARGB(255, 112, 104, 104),
                ),
                const SizedBox(height: 12),
                Text(
                  '未发现设备',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '当前没有设备连接到电脑',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '请确保设备已连接并开启开发者模式',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    'hdc list targets 返回 [Empty]',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.refreshDevices(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新扫描'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // 显示所有设备列表
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.connectedDevices.length,
        itemBuilder: (context, index) {
          final device = provider.connectedDevices[index];
          final isSelected = device == provider.selectedDevice;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (!isSelected) {
                  provider.selectDevice(device);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已选择设备: $device'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  Icon(
                    Icons.smartphone,
                    color: isSelected ? Colors.green : Colors.grey,
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.green : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $device',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  if (!isSelected)
                    ElevatedButton(
                      onPressed: () {
                        provider.selectDevice(device);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已选择设备: $device'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(60, 32),
                      ),
                      child: const Text(
                        '选择',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
  }

  void _showAddNetworkDeviceDialog(BuildContext context, AppProvider provider) {
    final TextEditingController ipController = TextEditingController();
    final TextEditingController portController = TextEditingController();
    bool isConnecting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi, color: Colors.blue),
              SizedBox(width: 8),
              Text('添加网络设备'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'IP地址',
                  hintText: '例如: 192.168.1.100',
                  prefixIcon: Icon(Icons.computer),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: portController,
                decoration: const InputDecoration(
                  labelText: '端口号',
                  hintText: '例如: 37309',
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              if (isConnecting)
                const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('正在连接设备...'),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isConnecting ? null : () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: isConnecting ? null : () async {
                final ip = ipController.text.trim();
                final portText = portController.text.trim();
                
                if (ip.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入IP地址'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                int port = 8710;
                if (portText.isNotEmpty) {
                  port = int.tryParse(portText) ?? 8710;
                }
                
                setState(() {
                  isConnecting = true;
                });
                
                try {
                  final networkService = NetworkHdcService();
                  final success = await networkService.connectToDeviceWithPort(ip, port);
                  
                  setState(() {
                    isConnecting = false;
                  });
                  
                  if (success) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('成功连接到设备 $ip:$port'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // 刷新设备列表
                    provider.refreshDevices();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('连接设备失败 $ip:$port'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() {
                    isConnecting = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('连接出错: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('连接'),
            ),
          ],
        ),
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
            _buildGuideStep(context, '6', '点击"选择"按钮或直接点击设备来选择目标设备'),
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