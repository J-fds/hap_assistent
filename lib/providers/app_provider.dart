import 'package:flutter/foundation.dart';
import '../services/harmony_service.dart';

class AppProvider extends ChangeNotifier {
  final HarmonyService _harmonyService = HarmonyService();
  
  // 应用状态
  bool _isInitialized = false;
  bool _isToolsInstalled = false;
  bool _isLoading = false;
  String _statusMessage = '正在初始化...';
  double _downloadProgress = 0.0;
  
  // 设备相关
  List<String> _connectedDevices = [];
  String? _selectedDevice;
  
  // HAP文件相关
  String? _selectedHapPath;
  List<String> _installedApps = [];
  
  // 日志
  List<String> _logs = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isToolsInstalled => _isToolsInstalled;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  double get downloadProgress => _downloadProgress;
  List<String> get connectedDevices => _connectedDevices;
  String? get selectedDevice => _selectedDevice;
  String? get selectedHapPath => _selectedHapPath;
  List<String> get installedApps => _installedApps;
  List<String> get logs => _logs;

  /// 初始化应用
  Future<void> initialize() async {
    _setLoading(true, '正在初始化应用...');
    
    try {
      await _harmonyService.initialize();
      _isToolsInstalled = _harmonyService.isToolsInstalled;
      _isInitialized = true;
      
      if (_isToolsInstalled) {
        _setStatus('鸿蒙开发工具已就绪');
        // 延迟刷新设备列表，避免在初始化时触发状态更新冲突
        Future.delayed(const Duration(milliseconds: 100), () {
          refreshDevices();
        });
      } else {
        _setStatus('需要下载鸿蒙开发工具');
      }
    } catch (e) {
      _setStatus('初始化失败: $e');
      _addLog('初始化错误: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 下载并安装开发工具
  Future<bool> downloadAndInstallTools() async {
    _setLoading(true, '正在下载鸿蒙开发工具...');
    _downloadProgress = 0.0;
    
    try {
      final success = await _harmonyService.downloadAndInstallTools((progress) {
        _downloadProgress = progress;
        _setStatus('下载进度: ${(progress * 100).toStringAsFixed(1)}%');
        // 减少频繁的UI更新，只在进度变化较大时更新
        if ((progress * 100).round() % 5 == 0) {
          notifyListeners();
        }
      });
      
      if (success) {
        _isToolsInstalled = true;
        _setStatus('鸿蒙开发工具安装完成');
        _addLog('开发工具安装成功');
        // 延迟刷新设备列表，避免状态更新冲突
        Future.delayed(const Duration(milliseconds: 100), () {
          refreshDevices();
        });
        return true;
      } else {
        _setStatus('开发工具安装失败');
        _addLog('开发工具安装失败');
        return false;
      }
    } catch (e) {
      _setStatus('安装失败: $e');
      _addLog('安装错误: $e');
      return false;
    } finally {
      _setLoading(false);
      _downloadProgress = 0.0;
    }
  }

  /// 刷新设备列表
  Future<void> refreshDevices() async {
    if (!_isToolsInstalled) return;
    
    _setLoading(true, '正在扫描设备...');
    
    try {
       final devices = await _harmonyService.getConnectedDevices();
       
       _connectedDevices = devices;
       
       if (_connectedDevices.isNotEmpty) {
         // 如果之前选择的设备不在新列表中，清除选择
         if (_selectedDevice != null && !_connectedDevices.contains(_selectedDevice)) {
           _selectedDevice = null;
           _installedApps.clear();
         }
         
         // 如果没有选择设备，自动选择第一个设备
         if (_selectedDevice == null) {
           _selectedDevice = _connectedDevices.first;
           _addLog('自动选择设备: $_selectedDevice');
         }
         
         _setStatus('发现 ${_connectedDevices.length} 个设备');
         // 刷新已安装应用
         refreshInstalledApps();
       } else {
         _selectedDevice = null;
         _installedApps.clear();
         _setStatus('未发现连接的设备');
       }
       
       _addLog('设备扫描完成，发现 ${devices.length} 个设备');
    } catch (e) {
      _setStatus('扫描设备失败: $e');
      _addLog('设备扫描错误: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 选择设备
  void selectDevice(String deviceId) {
    if (_connectedDevices.contains(deviceId)) {
      _selectedDevice = deviceId;
      _addLog('选择设备: $deviceId');
      
      notifyListeners();
      refreshInstalledApps();
    }
  }

  /// 选择HAP文件
  void selectHapFile(String hapPath) {
    if (_harmonyService.isValidHapFile(hapPath)) {
      _selectedHapPath = hapPath;
      _addLog('选择HAP文件: $hapPath');
      notifyListeners();
    } else {
      _addLog('无效的HAP文件: $hapPath');
    }
  }

  /// 安装HAP包
  Future<bool> installHap() async {
    if (_selectedHapPath == null) {
      _addLog('请先选择HAP文件');
      return false;
    }
    
    if (_selectedDevice == null) {
      _addLog('请先选择目标设备');
      return false;
    }
    
    _setLoading(true, '正在安装HAP包...');
    
    try {
      final success = await _harmonyService.installHap(_selectedHapPath!, _selectedDevice);
      
      if (success) {
        _setStatus('HAP包安装成功');
        _addLog('HAP包安装成功: $_selectedHapPath');
        await refreshInstalledApps();
        return true;
      } else {
        _setStatus('HAP包安装失败');
        _addLog('HAP包安装失败');
        return false;
      }
    } catch (e) {
      _setStatus('安装失败: $e');
      _addLog('安装错误: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 卸载应用
  Future<bool> uninstallApp(String packageName) async {
    if (_selectedDevice == null) {
      _addLog('请先选择目标设备');
      return false;
    }
    
    _setLoading(true, '正在卸载应用...');
    
    try {
      final success = await _harmonyService.uninstallApp(packageName, _selectedDevice);
      
      if (success) {
        _setStatus('应用卸载成功');
        _addLog('应用卸载成功: $packageName');
        await refreshInstalledApps();
        return true;
      } else {
        _setStatus('应用卸载失败');
        _addLog('应用卸载失败: $packageName');
        return false;
      }
    } catch (e) {
      _setStatus('卸载失败: $e');
      _addLog('卸载错误: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 刷新已安装应用列表
  Future<void> refreshInstalledApps() async {
    if (!_isToolsInstalled || _selectedDevice == null) {
      _installedApps.clear();
      notifyListeners();
      return;
    }
    
    try {
      _installedApps = await _harmonyService.getInstalledApps(_selectedDevice);
      _addLog('获取到 ${_installedApps.length} 个已安装应用');
      notifyListeners();
    } catch (e) {
      _addLog('获取应用列表失败: $e');
    }
  }

  /// 清除HAP文件选择
  void clearHapSelection() {
    _selectedHapPath = null;
    notifyListeners();
  }

  /// 清除日志
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  /// 设置加载状态
  void _setLoading(bool loading, [String? message]) {
    _isLoading = loading;
    if (message != null) {
      _statusMessage = message;
    }
    notifyListeners();
  }

  /// 设置状态消息
  void _setStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  /// 添加日志
  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logs.add('[$timestamp] $message');
    
    // 限制日志数量
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _harmonyService.dispose();
    super.dispose();
  }
}