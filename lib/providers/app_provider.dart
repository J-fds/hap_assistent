import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/harmony_service.dart';
import '../services/package_service.dart';
import '../models/device.dart';
import '../models/app.dart';
import '../models/package_file.dart';

class AppProvider extends ChangeNotifier {
  final HarmonyService _harmonyService = HarmonyService();
  final PackageService _packageService = PackageService();
  
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
  
  // 包管理相关
  String _packageServerIp = '10.44.139.92'; // 默认打包机IP
  String _sharedFolderPath = '/Users/customer/harmony/haps/'; // 默认HAP文件路径
  List<PackageFile> _packageFiles = [];
  bool _isLoadingPackages = false;
  Map<String, double> _installProgress = {}; // 安装进度
  bool _autoSelectLatest = true; // 自动选择最新包开关
  
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
  
  // 包管理相关getters
  String get packageServerIp => _packageServerIp;
  String get sharedFolderPath => _sharedFolderPath;
  List<PackageFile> get packageFiles => _packageFiles;
  bool get isLoadingPackages => _isLoadingPackages;
  Map<String, double> get installProgress => _installProgress;
  bool get autoSelectLatest => _autoSelectLatest;

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
        // 自动获取共享文件夹的包文件列表
        Future.delayed(const Duration(milliseconds: 200), () {
          refreshPackageFiles();
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
  
  /// 设置包服务器配置
  void setPackageServerConfig(String ip, String folderPath) {
    _packageServerIp = ip;
    _sharedFolderPath = folderPath;
    _addLog('更新包服务器配置: $ip$folderPath');
    notifyListeners();
  }

  /// 设置包服务器IP地址
  void setPackageServerIp(String ip) {
    _packageServerIp = ip;
    _addLog('更新打包机IP: $ip');
    notifyListeners();
  }

  /// 设置共享文件夹路径
  void setSharedFolderPath(String folderPath) {
    _sharedFolderPath = folderPath;
    _addLog('更新文件路径: $folderPath');
    notifyListeners();
  }

  /// 获取共享文件夹的完整路径（根据操作系统）
  String getSharedFolderFullPath() {
    if (Platform.isWindows) {
      // Windows: \\IP\共享文件夹名\路径
      // 支持UNC路径和映射网络驱动器
      if (_sharedFolderPath.startsWith('/')) {
        // 如果路径以/开头，转换为Windows格式
        String windowsPath = _sharedFolderPath.replaceAll('/', '\\');
        return '\\\\$_packageServerIp$windowsPath';
      } else {
        // 默认harmony共享文件夹
        return '\\\\$_packageServerIp\\harmony\\haps\\';
      }
    } else if (Platform.isMacOS) {
      // macOS: smb://IP/共享文件夹名/路径
      // 支持SMB协议连接
      if (_sharedFolderPath.startsWith('/')) {
        return 'smb://$_packageServerIp$_sharedFolderPath';
      } else {
        return 'smb://$_packageServerIp/harmony/haps/';
      }
    } else {
      // Linux等其他系统: //IP/共享文件夹名/路径
      if (_sharedFolderPath.startsWith('/')) {
        return '//$_packageServerIp$_sharedFolderPath';
      } else {
        return '//$_packageServerIp/harmony/haps/';
      }
    }
  }

  /// 获取本地挂载路径（用于文件操作）
  String getLocalMountPath() {
    if (Platform.isWindows) {
      // Windows可以直接使用UNC路径
      return getSharedFolderFullPath();
    } else if (Platform.isMacOS) {
      // macOS挂载点通常在/Volumes/下
      return '/Volumes/harmony/haps/';
    } else {
      // Linux挂载点
      return '/mnt/harmony/haps/';
    }
  }
  
  /// 刷新包文件列表
  Future<void> refreshPackageFiles() async {
    _isLoadingPackages = true;
    notifyListeners();
    
    try {
      _addLog('正在刷新包文件列表...');
      _addLog('连接打包机: $_packageServerIp');
      _addLog('文件路径: $_sharedFolderPath');
      
      // 首先检查打包机连接状态
      final isConnected = await _packageService.checkConnection(_packageServerIp);
      if (!isConnected) {
        throw Exception('无法连接到打包机 $_packageServerIp，请检查IP地址和网络连接');
      }
      
      // 从打包机获取包文件列表
      _packageFiles = await _packageService.fetchPackageFiles(
        _packageServerIp,
        _sharedFolderPath,
      );
      
      _addLog('成功获取到 ${_packageFiles.length} 个包文件');
      
      // 如果开启自动选择最新包，则自动选择
      if (_autoSelectLatest && _packageFiles.isNotEmpty) {
        selectLatestPackageFile();
      }
    } catch (e) {
      _addLog('刷新包文件列表失败: $e');
      // 如果网络请求失败，清空包文件列表
      _packageFiles = [];
    } finally {
      _isLoadingPackages = false;
      notifyListeners();
    }
  }
  
  /// 设置自动选择最新包开关
  void setAutoSelectLatest(bool value) {
    _autoSelectLatest = value;
    _addLog('${value ? '开启' : '关闭'}自动选择最新包');
    
    // 如果开启且有包文件，立即选择最新的
    if (value && _packageFiles.isNotEmpty) {
      selectLatestPackageFile();
    }
    
    notifyListeners();
  }
  
  /// 自动选择最新的包文件
  void selectLatestPackageFile() {
    if (_packageFiles.isNotEmpty) {
      // 包文件已经按创建时间排序，第一个就是最新的
      final latestFile = _packageFiles.first;
      selectHapFile(latestFile.path);
      _addLog('自动选择最新包文件: ${latestFile.name}');
    } else {
      _addLog('没有找到可用的包文件');
    }
  }
  
  /// 安装包文件
  Future<bool> installPackageFile(PackageFile packageFile) async {
    if (_selectedDevice == null) {
      _addLog('请先选择目标设备');
      return false;
    }
    
    final packageId = packageFile.name;
    _installProgress[packageId] = 0.0;
    notifyListeners();
    
    try {
      _addLog('开始安装包: ${packageFile.name}');
      
      // 模拟安装进度
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        _installProgress[packageId] = i / 100.0;
        notifyListeners();
      }
      
      // 模拟安装结果
      final success = DateTime.now().millisecond % 2 == 0; // 随机成功/失败
      
      if (success) {
        _addLog('包安装成功: ${packageFile.name}');
        await refreshInstalledApps();
      } else {
        _addLog('包安装失败: ${packageFile.name}');
      }
      
      return success;
    } catch (e) {
      _addLog('安装错误: $e');
      return false;
    } finally {
      _installProgress.remove(packageId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _harmonyService.dispose();
    _packageService.dispose();
    super.dispose();
  }
}