import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/network_hdc_service.dart';
import '../services/harmony_service.dart';
import 'package:logger/logger.dart';

/// 网络设备管理组件
class NetworkDeviceManager extends StatefulWidget {
  const NetworkDeviceManager({Key? key}) : super(key: key);

  @override
  State<NetworkDeviceManager> createState() => _NetworkDeviceManagerState();
}

class _NetworkDeviceManagerState extends State<NetworkDeviceManager> {
  final NetworkHdcService _networkService = NetworkHdcService();
  final HarmonyService _harmonyService = HarmonyService();
  final Logger _logger = Logger();
  
  String? _localIp;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    try {
      await _networkService.initialize();
      final ip = await _networkService.getLocalIpAddress();
      setState(() {
        _localIp = ip;
        _isInitialized = true;
      });
    } catch (e) {
      _logger.e('初始化网络服务失败: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }
  
  @override
  void dispose() {
    _networkService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildLocalInfo(),
          const SizedBox(height: 16),
          _buildScanSection(),
          const SizedBox(height: 16),
          _buildDeviceList(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.wifi, size: 24),
        const SizedBox(width: 8),
        const Text(
          '网络设备管理',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showHelpDialog,
          tooltip: '使用说明',
        ),
      ],
    );
  }
  
  Widget _buildLocalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '本机信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('IP地址: '),
                Text(
                  _localIp ?? '未获取',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (_localIp != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () => _copyToClipboard(_localIp!),
                    tooltip: '复制IP地址',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '手机连接步骤：\n'
              '1. 确保手机和电脑在同一WiFi网络\n'
              '2. 在手机上打开开发者选项\n'
              '3. 启用"USB调试"和"无线调试"\n'
              '4. 点击下方"扫描设备"按钮',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScanSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '设备扫描',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddDeviceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('手动添加'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                StreamBuilder<List<NetworkDevice>>(
                  stream: _networkService.devicesStream,
                  builder: (context, snapshot) {
                    final isScanning = _networkService.isScanning;
                    return ElevatedButton.icon(
                      onPressed: isScanning ? null : _scanDevices,
                      icon: isScanning 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(isScanning ? '扫描中...' : '扫描设备'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isScanning ? Colors.grey : null,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '扫描局域网中的鸿蒙设备（可能需要1-2分钟）',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeviceList() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '发现的设备',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<NetworkDevice>>(
                  stream: _networkService.devicesStream,
                  builder: (context, snapshot) {
                    final devices = snapshot.data ?? [];
                    
                    if (devices.isEmpty) {
                      return const Center(
                        child: Text(
                          '暂无发现设备\n请确保设备已开启无线调试并点击"扫描设备"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return _buildDeviceItem(device);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDeviceItem(NetworkDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          device.isConnected ? Icons.smartphone_outlined : Icons.phone_android,
          color: device.isConnected ? Colors.green : Colors.grey,
        ),
        title: Text(device.deviceName ?? '未知设备'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('IP: ${device.ip}'),
            Text(
              device.isConnected ? '已连接' : '未连接',
              style: TextStyle(
                color: device.isConnected ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                device.isConnected ? Icons.link_off : Icons.link,
                color: device.isConnected ? Colors.red : Colors.blue,
              ),
              onPressed: () => device.isConnected 
                  ? _disconnectDevice(device.ip)
                  : _connectDevice(device.ip),
              tooltip: device.isConnected ? '断开连接' : '连接设备',
            ),
            if (device.isConnected)
              IconButton(
                icon: const Icon(Icons.install_mobile, color: Colors.green),
                onPressed: () => _installHapToDevice(device.ip),
                tooltip: '安装HAP',
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
  
  Future<void> _scanDevices() async {
    try {
      await _networkService.scanNetworkDevices();
    } catch (e) {
      _showErrorSnackBar('扫描设备失败: $e');
    }
  }
  
  Future<void> _connectDevice(String ip) async {
    try {
      final success = await _networkService.connectToDevice(ip);
      if (success) {
        _showSuccessSnackBar('设备连接成功: $ip');
      } else {
        _showErrorSnackBar('设备连接失败: $ip');
      }
    } catch (e) {
      _showErrorSnackBar('连接设备时发生错误: $e');
    }
  }
  
  Future<void> _disconnectDevice(String ip) async {
    try {
      final success = await _networkService.disconnectFromDevice(ip);
      if (success) {
        _showSuccessSnackBar('设备断开连接: $ip');
      } else {
        _showErrorSnackBar('断开连接失败: $ip');
      }
    } catch (e) {
      _showErrorSnackBar('断开连接时发生错误: $e');
    }
  }
  
  Future<void> _installHapToDevice(String ip) async {
    // 这里需要选择HAP文件
    _showInfoSnackBar('请先在HAP安装页面选择文件，然后选择网络设备进行安装');
  }
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar('已复制到剪贴板: $text');
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('网络连接使用说明'),
        content: const SingleChildScrollView(
          child: Text(
            '网络HDC连接功能说明：\n\n'
            '1. 确保手机和电脑连接到同一WiFi网络\n\n'
            '2. 在鸿蒙手机上开启开发者选项：\n'
            '   - 设置 > 关于手机 > 版本号（连续点击7次）\n\n'
            '3. 开启无线调试：\n'
            '   - 设置 > 系统和更新 > 开发人员选项\n'
            '   - 开启"USB调试"\n'
            '   - 开启"无线调试"\n\n'
            '4. 点击"扫描设备"按钮搜索网络中的设备\n\n'
            '5. 找到设备后点击"连接"按钮建立连接\n\n'
            '6. 连接成功后即可进行无线HAP安装\n\n'
            '注意：首次连接可能需要在手机上确认调试授权。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// 显示手动添加设备对话框
  void _showAddDeviceDialog() {
    final TextEditingController ipController = TextEditingController();
    final TextEditingController portController = TextEditingController(text: '8710');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('手动添加设备'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请输入手机的IP地址：',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  hintText: '例如：192.168.1.100',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text(
                '请输入端口号（可选）：',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: portController,
                decoration: const InputDecoration(
                  hintText: '默认：8710（常用端口：5555, 5037）',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text(
                '提示：\n1. 确保手机和电脑在同一WiFi网络\n2. 手机需开启"无线调试"功能\n3. 可在手机设置中查看IP地址\n4. 常用端口：8710（默认）、5555、5037',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ip = ipController.text.trim();
                final portText = portController.text.trim();
                
                if (ip.isEmpty) {
                  _showErrorSnackBar('请输入IP地址');
                  return;
                }
                
                // 验证IP地址格式
                final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
                if (!ipRegex.hasMatch(ip)) {
                  _showErrorSnackBar('IP地址格式不正确');
                  return;
                }
                
                // 验证端口号
                int port = 8710; // 默认端口
                if (portText.isNotEmpty) {
                  final parsedPort = int.tryParse(portText);
                  if (parsedPort == null || parsedPort < 1 || parsedPort > 65535) {
                    _showErrorSnackBar('端口号必须是1-65535之间的数字');
                    return;
                  }
                  port = parsedPort;
                }
                
                Navigator.of(context).pop();
                
                // 尝试连接设备
                try {
                  _showSuccessSnackBar('正在尝试连接设备...');
                  final success = await _networkService.connectToDeviceWithPort(ip, port);
                  if (success) {
                    _showSuccessSnackBar('设备连接成功！');
                  } else {
                    _showErrorSnackBar('连接失败，请检查IP地址、端口号和网络设置');
                  }
                } catch (e) {
                  _showErrorSnackBar('连接失败: $e');
                }
              },
              child: const Text('连接'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}