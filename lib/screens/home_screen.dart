import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../widgets/device_selector.dart';
import '../widgets/device_manager.dart';
import '../widgets/hap_installer.dart';
import '../widgets/package_manager.dart';
import '../widgets/log_viewer.dart';
import '../widgets/tools_manager.dart';
import '../widgets/network_device_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // 初始化应用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 切换到设备管理标签页
  void switchToDeviceTab() {
    _tabController.animateTo(1); // 设备管理是第2个标签页，索引为1
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('鸿蒙HAP安装助手'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.connectedDevices.isNotEmpty 
                    ? Icons.smartphone 
                    : Icons.smartphone_outlined,
                  color: provider.connectedDevices.isNotEmpty 
                    ? Colors.green 
                    : Colors.grey,
                ),
                onPressed: provider.isLoading ? null : () {
                  provider.refreshDevices();
                },
                tooltip: '刷新设备列表',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.install_mobile), text: 'HAP安装'),
            Tab(icon: Icon(Icons.devices), text: '设备管理'),
            Tab(icon: Icon(Icons.apps), text: '包管理'),
            Tab(icon: Icon(Icons.terminal), text: '日志'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 状态栏
          _buildStatusBar(),
          // 主要内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                HapInstaller(),
                DeviceManager(),
                PackageManager(),
                LogViewer(),
              ],
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildStatusBar() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (provider.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (provider.isLoading) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (provider.downloadProgress > 0 && provider.downloadProgress < 1)
                Container(
                  width: 100,
                  height: 4,
                  margin: const EdgeInsets.only(left: 8),
                  child: LinearProgressIndicator(
                    value: provider.downloadProgress,
                  ),
                ),
              if (provider.connectedDevices.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${provider.connectedDevices.length} 设备',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showToolsInstallDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ToolsManager(),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '快速操作',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text('选择HAP文件'),
              onTap: () {
                Navigator.pop(context);
                _pickHapFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('刷新设备'),
              onTap: () {
                Navigator.pop(context);
                context.read<AppProvider>().refreshDevices();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('清除日志'),
              onTap: () {
                Navigator.pop(context);
                context.read<AppProvider>().clearLogs();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickHapFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['hap', 'app'],
        dialogTitle: '选择HAP文件',
      );

      if (result != null && result.files.single.path != null) {
        final hapPath = result.files.single.path!;
        if (mounted) {
          context.read<AppProvider>().selectHapFile(hapPath);
          // 切换到HAP安装标签页
          _tabController.animateTo(0);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}