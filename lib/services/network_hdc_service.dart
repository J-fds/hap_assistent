import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';
import 'harmony_service.dart';

/// 网络设备信息
class NetworkDevice {
  final String ip;
  final String? deviceName;
  final bool isConnected;
  final String? deviceId;
  
  NetworkDevice({
    required this.ip,
    this.deviceName,
    this.isConnected = false,
    this.deviceId,
  });
  
  @override
  String toString() {
    return 'NetworkDevice(ip: $ip, name: $deviceName, connected: $isConnected, id: $deviceId)';
  }
}

/// 网络HDC服务
class NetworkHdcService {
  static final NetworkHdcService _instance = NetworkHdcService._internal();
  factory NetworkHdcService() => _instance;
  NetworkHdcService._internal();

  final Logger _logger = Logger();
  final ProcessManager _processManager = const LocalProcessManager();
  final Platform _platform = const LocalPlatform();
  final NetworkInfo _networkInfo = NetworkInfo();
  final HarmonyService _harmonyService = HarmonyService();
  
  // 网络设备列表
  final List<NetworkDevice> _networkDevices = [];
  
  // 状态流控制器
  StreamController<List<NetworkDevice>>? _devicesController;
  
  // 扫描状态
  bool _isScanning = false;
  
  /// 获取设备流
  Stream<List<NetworkDevice>> get devicesStream {
    _devicesController ??= StreamController<List<NetworkDevice>>.broadcast();
    return _devicesController!.stream;
  }
  
  /// 获取当前网络设备列表
  List<NetworkDevice> get networkDevices => List.unmodifiable(_networkDevices);
  
  /// 是否正在扫描
  bool get isScanning => _isScanning;
  
  /// 初始化网络HDC服务
  Future<void> initialize() async {
    _logger.i('初始化网络HDC服务...');
    await _harmonyService.initialize();
  }
  
  /// 获取本机IP地址
  Future<String?> getLocalIpAddress() async {
    try {
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty) {
        _logger.i('本机IP地址: $wifiIP');
        return wifiIP;
      }
      return null;
    } catch (e) {
      _logger.e('获取本机IP地址失败: $e');
      return null;
    }
  }
  
  /// 获取网络子网
  Future<String?> getSubnet() async {
    final ip = await getLocalIpAddress();
    if (ip != null) {
      final parts = ip.split('.');
      if (parts.length == 4) {
        return '${parts[0]}.${parts[1]}.${parts[2]}';
      }
    }
    return null;
  }
  
  /// 扫描网络中的鸿蒙设备
  Future<void> scanNetworkDevices() async {
    if (_isScanning) {
      _logger.w('正在扫描中，跳过重复扫描');
      return;
    }
    
    _isScanning = true;
    _logger.i('开始扫描网络设备...');
    
    try {
      final subnet = await getSubnet();
      if (subnet == null) {
        _logger.e('无法获取网络子网');
        return;
      }
      
      _networkDevices.clear();
      _devicesController?.add(List.from(_networkDevices));
      
      // 扫描IP范围 1-254
      final futures = <Future>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        futures.add(_checkDeviceAtIp(ip));
      }
      
      // 等待所有扫描完成
      await Future.wait(futures);
      
      _logger.i('网络扫描完成，发现 ${_networkDevices.length} 个设备');
      _devicesController ??= StreamController<List<NetworkDevice>>.broadcast();
      if (!_devicesController!.isClosed) {
        _devicesController!.add(List.from(_networkDevices));
      }
      
    } catch (e) {
      _logger.e('扫描网络设备失败: $e');
    } finally {
      _isScanning = false;
    }
  }
  
  /// 检查指定IP是否为鸿蒙设备
  Future<void> _checkDeviceAtIp(String ip) async {
    try {
      // 首先ping检查设备是否在线
      final pingResult = await _processManager.run([
        'ping',
        '-c', '1',
        '-t', '1', // 1秒超时 (macOS使用-t)
        ip,
      ]);
      
      if (pingResult.exitCode != 0) {
        return; // 设备不在线
      }
      
      // 尝试连接常用的HDC端口并验证是否为鸿蒙设备
      final ports = [8710, 5555, 5037]; // 常用的调试端口
      String? connectedPort;
      
      for (final port in ports) {
        try {
          final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 1));
          await socket.close();
          
          // 尝试使用HDC命令验证是否为鸿蒙设备
          final hdcPath = _harmonyService.getHdcPath();
          final testResult = await _processManager.run([
            hdcPath,
            'tconn',
            '$ip:$port',
          ]);
          
          if (testResult.exitCode == 0) {
            // 立即断开测试连接
            await _processManager.run([
              hdcPath,
              'tdisconn',
              '$ip:$port',
            ]);
            
            connectedPort = port.toString();
            break;
          }
        } catch (e) {
          // 尝试下一个端口
          continue;
        }
      }
      
      if (connectedPort != null) {
        // 确认是鸿蒙设备
        final device = NetworkDevice(
          ip: ip,
          deviceName: '鸿蒙设备 ($ip:$connectedPort)',
          isConnected: false,
        );
        
        _networkDevices.add(device);
        _devicesController?.add(List.from(_networkDevices));
        
        _logger.i('发现鸿蒙设备: $ip:$connectedPort');
      }
      
    } catch (e) {
      // 连接失败，不是鸿蒙设备或端口未开放
      // 不记录错误，避免日志过多
    }
  }
  
  /// 连接到网络设备（使用默认端口8710）
  Future<bool> connectToDevice(String ip) async {
    return connectToDeviceWithPort(ip, 8710);
  }
  
  /// 连接到网络设备（指定端口）
  Future<bool> connectToDeviceWithPort(String ip, int port) async {
    try {
      _logger.i('尝试连接到设备: $ip:$port');
      
      // 使用hdc连接网络设备
      final hdcPath = _harmonyService.getHdcPath();
      final result = await _processManager.run([
        hdcPath,
        'tconn',
        '$ip:$port',
      ]);
      
      if (result.exitCode == 0) {
        return await _verifyAndUpdateConnection(ip, port, hdcPath);
      } else {
        _logger.w('首次连接失败，尝试重启HDC服务器后重试: ${result.stderr}');
        
        // 执行 hdc kill -r 重启服务器
        final killResult = await _processManager.run([
          hdcPath,
          'kill',
          '-r',
        ]);
        
        if (killResult.exitCode == 0) {
          _logger.i('HDC服务器重启成功，等待服务器启动...');
          // 等待服务器重启完成
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // 重新尝试连接
          final retryResult = await _processManager.run([
            hdcPath,
            'tconn',
            '$ip:$port',
          ]);
          
          if (retryResult.exitCode == 0) {
            _logger.i('重试连接成功: $ip:$port');
            return await _verifyAndUpdateConnection(ip, port, hdcPath);
          } else {
            _logger.e('重试连接仍然失败: ${retryResult.stderr}');
            return false;
          }
        } else {
          _logger.e('重启HDC服务器失败: ${killResult.stderr}');
          return false;
        }
      }
    } catch (e) {
      _logger.e('连接设备时发生错误: $e');
      return false;
    }
  }
  
  /// 验证连接并更新设备状态
  Future<bool> _verifyAndUpdateConnection(String ip, int port, String hdcPath) async {
    _logger.i('HDC连接命令执行成功: $ip:$port');
    
    // 等待连接稳定
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 验证连接是否真正建立 - 检查设备列表
    final verifyResult = await _processManager.run([
      hdcPath,
      'list',
      'targets',
    ]);
    
    bool isReallyConnected = false;
    if (verifyResult.exitCode == 0) {
      final output = verifyResult.stdout.toString().trim();
      _logger.i('设备列表验证结果: $output');
      
      // 如果输出为空或只包含[Empty]，尝试其他验证方法
      if (output.isEmpty || output.contains('[Empty]')) {
        // 尝试使用shell命令验证连接
        final shellResult = await _processManager.run([
          hdcPath,
          'shell',
          '-t',
          '$ip:$port',
          'echo',
          'test'
        ]);
        isReallyConnected = shellResult.exitCode == 0;
        _logger.i('Shell命令验证结果: ${shellResult.exitCode == 0 ? "成功" : "失败"}');
      } else {
        // 检查输出中是否包含该IP地址
        isReallyConnected = output.contains(ip) || output.contains('$ip:$port');
      }
    }
    
    if (isReallyConnected) {
      _logger.i('设备连接验证成功: $ip:$port');
      
      // 更新设备状态
      final deviceIndex = _networkDevices.indexWhere((d) => d.ip == ip);
      if (deviceIndex != -1) {
        final device = _networkDevices[deviceIndex];
        _networkDevices[deviceIndex] = NetworkDevice(
          ip: device.ip,
          deviceName: device.deviceName,
          isConnected: true,
          deviceId: ip, // 使用IP作为设备ID
        );
        _devicesController?.add(List.from(_networkDevices));
      } else {
        // 如果设备不在列表中，添加新设备
        _networkDevices.add(NetworkDevice(
          ip: ip,
          deviceName: '手动添加设备',
          isConnected: true,
          deviceId: ip,
        ));
        _devicesController?.add(List.from(_networkDevices));
      }
      
      return true;
    } else {
      _logger.w('HDC连接命令成功但设备未在列表中，可能连接失败');
      return false;
    }
  }
  
  /// 断开网络设备连接（使用默认端口8710）
  Future<bool> disconnectFromDevice(String ip) async {
    return disconnectFromDeviceWithPort(ip, 8710);
  }
  
  /// 断开网络设备连接（指定端口）
  Future<bool> disconnectFromDeviceWithPort(String ip, int port) async {
    try {
      _logger.i('断开设备连接: $ip:$port');
      
      final hdcPath = _harmonyService.getHdcPath();
      final result = await _processManager.run([
        hdcPath,
        'tdisconn',
        '$ip:$port',
      ]);
      
      if (result.exitCode == 0) {
        _logger.i('成功断开设备连接: $ip:$port');
        
        // 更新设备状态
        final deviceIndex = _networkDevices.indexWhere((d) => d.ip == ip);
        if (deviceIndex != -1) {
          final device = _networkDevices[deviceIndex];
          _networkDevices[deviceIndex] = NetworkDevice(
            ip: device.ip,
            deviceName: device.deviceName,
            isConnected: false,
            deviceId: null,
          );
          _devicesController?.add(List.from(_networkDevices));
        }
        
        return true;
      } else {
        _logger.e('断开设备连接失败: ${result.stderr}');
        return false;
      }
    } catch (e) {
      _logger.e('断开设备连接时发生错误: $e');
      return false;
    }
  }
  
  /// 通过网络安装HAP到指定设备
  Future<bool> installHapToNetworkDevice(String hapPath, String deviceIp) async {
    try {
      // 确保设备已连接
      final device = _networkDevices.firstWhere(
        (d) => d.ip == deviceIp,
        orElse: () => throw Exception('设备未找到: $deviceIp'),
      );
      
      if (!device.isConnected) {
        _logger.w('设备未连接，尝试连接...');
        final connected = await connectToDevice(deviceIp);
        if (!connected) {
          throw Exception('无法连接到设备: $deviceIp');
        }
      }
      
      // 使用HarmonyService安装HAP
      return await _harmonyService.installHap(hapPath, deviceIp);
      
    } catch (e) {
      _logger.e('网络安装HAP失败: $e');
      return false;
    }
  }
  
  /// 生成二维码数据（用于手机扫码连接）
  String generateQrCodeData() {
    // 二维码包含本机IP和端口信息
    // 格式: hdc://ip:port
    return 'hdc://192.168.1.100:8710'; // 这里需要动态获取本机IP
  }
  
  /// 释放资源
  void dispose() {
    if (_devicesController != null && !_devicesController!.isClosed) {
      _devicesController!.close();
      _devicesController = null;
    }
  }
}