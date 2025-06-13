import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:process/process.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
import 'package:platform/platform.dart';

class HarmonyService {
  static final HarmonyService _instance = HarmonyService._internal();
  factory HarmonyService() => _instance;
  HarmonyService._internal();

  final Logger _logger = Logger();
  final Dio _dio = Dio();
  final ProcessManager _processManager = const LocalProcessManager();
  final Platform _platform = const LocalPlatform();

  String? _toolsPath;
  String? _hdcPath;
  bool _isToolsInstalled = false;

  // 鸿蒙开发工具下载URL
  static const String _harmonyToolsUrl = 'https://developer.harmonyos.com/deveco-developer-suite/releases';
  
  // 支持的HAP文件扩展名
  static const List<String> supportedExtensions = ['.hap', '.app'];

  /// 初始化服务
  Future<void> initialize() async {
    _logger.i('初始化鸿蒙服务...');
    await _checkToolsInstallation();
  }

  /// 检查开发工具是否已安装
  Future<void> _checkToolsInstallation() async {
    try {
      // 首先尝试提取并使用捆绑的hdc工具
      await _extractBundledHdc();
      
      if (_hdcPath != null && await File(_hdcPath!).exists()) {
        _isToolsInstalled = true;
        _logger.i('使用捆绑的hdc工具: $_hdcPath');
        return;
      }
      
      // 如果捆绑工具不可用，检查外部安装的工具
      final appDir = await getApplicationDocumentsDirectory();
      _toolsPath = path.join(appDir.path, 'harmony_tools');
      
      final toolsDir = Directory(_toolsPath!);
      if (await toolsDir.exists()) {
        // 检查hdc工具是否存在
        final hdcPath = _getExternalHdcPath();
        final hdcFile = File(hdcPath);
        _isToolsInstalled = await hdcFile.exists();
        
        if (_isToolsInstalled) {
          _hdcPath = hdcPath;
          _logger.i('鸿蒙开发工具已安装: $_toolsPath');
        } else {
          _logger.w('鸿蒙开发工具目录存在但hdc工具缺失');
        }
      } else {
        _logger.i('鸿蒙开发工具未安装');
        _isToolsInstalled = false;
      }
    } catch (e) {
      _logger.e('检查工具安装状态失败: $e');
      _isToolsInstalled = false;
    }
  }

  /// 提取捆绑的hdc工具
  Future<void> _extractBundledHdc() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final bundledToolsDir = path.join(appDir.path, 'bundled_tools');
      await Directory(bundledToolsDir).create(recursive: true);
      
      String hdcAssetPath;
      String hdcFileName;
      String? libAssetPath;
      String? libFileName;
      
      if (_platform.isWindows) {
        hdcAssetPath = 'assets/tools/windows/hdc.exe';
        hdcFileName = 'hdc.exe';
        libAssetPath = 'assets/tools/windows/libusb_shared.dll';
        libFileName = 'libusb_shared.dll';
      } else if (_platform.isMacOS) {
        hdcAssetPath = 'assets/tools/macos/hdc';
        hdcFileName = 'hdc';
        libAssetPath = 'assets/tools/macos/libusb_shared.dylib';
        libFileName = 'libusb_shared.dylib';
      } else {
        hdcAssetPath = 'assets/tools/linux/hdc';
        hdcFileName = 'hdc';
      }
      
      final hdcPath = path.join(bundledToolsDir, hdcFileName);
      
      // 检查是否已经提取过
      if (await File(hdcPath).exists()) {
        _hdcPath = hdcPath;
        return;
      }
      
      // 从assets中读取hdc工具
      final hdcByteData = await rootBundle.load(hdcAssetPath);
      final hdcBytes = hdcByteData.buffer.asUint8List();
      
      // 写入到本地文件
      await File(hdcPath).writeAsBytes(hdcBytes);
      
      // 提取依赖库（如果存在）
      if (libAssetPath != null && libFileName != null) {
        final libPath = path.join(bundledToolsDir, libFileName);
        try {
          final libByteData = await rootBundle.load(libAssetPath);
          final libBytes = libByteData.buffer.asUint8List();
          await File(libPath).writeAsBytes(libBytes);
          
          // 设置库文件权限
          if (!_platform.isWindows) {
            await _setExecutePermission(libPath);
            if (_platform.isMacOS) {
              await _removeQuarantineAttribute(libPath);
              await _addCodeSignature(libPath);
            }
          }
          _logger.i('成功提取依赖库: $libPath');
        } catch (e) {
          _logger.w('提取依赖库失败: $e');
        }
      }
      
      // 设置执行权限（macOS/Linux）
      if (!_platform.isWindows) {
        await _setExecutePermission(hdcPath);
        // Remove quarantine attribute and add code signature on macOS
        if (_platform.isMacOS) {
          await _removeQuarantineAttribute(hdcPath);
          await _addCodeSignature(hdcPath);
        }
      }
      
      _hdcPath = hdcPath;
      _logger.i('成功提取捆绑的hdc工具到: $hdcPath');
    } catch (e) {
      _logger.e('提取捆绑hdc工具失败: $e');
    }
  }
  
  /// 获取外部安装的hdc工具路径
  String _getExternalHdcPath() {
    if (_platform.isWindows) {
      return path.join(_toolsPath!, 'hdc.exe');
    } else {
      return path.join(_toolsPath!, 'hdc');
    }
  }
  
  /// 获取当前使用的hdc工具路径
  String _getHdcPath() {
    return _hdcPath ?? _getExternalHdcPath();
  }

  /// 下载并安装鸿蒙开发工具
  Future<bool> downloadAndInstallTools(Function(double)? onProgress) async {
    try {
      _logger.i('开始下载鸿蒙开发工具...');
      
      // 创建工具目录
      final toolsDir = Directory(_toolsPath!);
      if (!await toolsDir.exists()) {
        await toolsDir.create(recursive: true);
      }

      // 这里应该根据实际的鸿蒙工具下载链接进行下载
      // 由于官方链接可能变化，这里提供一个框架
      final downloadUrl = _getToolsDownloadUrl();
      
      if (downloadUrl == null) {
        _logger.e('无法获取工具下载链接');
        return false;
      }

      final zipPath = path.join(_toolsPath!, 'harmony_tools.zip');
      
      // 下载工具包
      await _dio.download(
        downloadUrl,
        zipPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      // 解压工具包
      await _extractTools(zipPath);
      
      // 删除压缩包
      await File(zipPath).delete();
      
      // 设置执行权限（macOS/Linux）
      if (!_platform.isWindows) {
        await _setExecutePermission(_getHdcPath());
      }

      _isToolsInstalled = true;
      _logger.i('鸿蒙开发工具安装完成');
      return true;
    } catch (e) {
      _logger.e('下载安装工具失败: $e');
      return false;
    }
  }

  /// 获取工具下载链接
  String? _getToolsDownloadUrl() {
    // 这里需要根据平台返回对应的下载链接
    // 实际使用时需要从鸿蒙官网获取最新的下载链接
    if (_platform.isWindows) {
      return 'https://example.com/harmony-tools-windows.zip';
    } else if (_platform.isMacOS) {
      return 'https://example.com/harmony-tools-macos.zip';
    }
    return null;
  }

  /// 解压工具包
  Future<void> _extractTools(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    for (final file in archive) {
      final filename = file.name;
      final filePath = path.join(_toolsPath!, filename);
      
      if (file.isFile) {
        final data = file.content as List<int>;
        await File(filePath).create(recursive: true);
        await File(filePath).writeAsBytes(data);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
  }

  /// 设置执行权限
  Future<void> _setExecutePermission(String filePath) async {
    try {
      // 设置文件为可执行权限 (755)
      final result = await _processManager.run(['chmod', '755', filePath]);
      if (result.exitCode != 0) {
        _logger.w('设置执行权限失败: ${result.stderr}');
      } else {
        _logger.i('成功设置执行权限: $filePath');
      }
    } catch (e) {
      _logger.e('设置执行权限时发生错误: $e');
    }
  }
  
  /// 移除macOS的quarantine属性
  Future<void> _removeQuarantineAttribute(String filePath) async {
    try {
      final result = await _processManager.run(['xattr', '-d', 'com.apple.quarantine', filePath]);
      if (result.exitCode != 0) {
        _logger.w('移除quarantine属性失败: ${result.stderr}');
      } else {
        _logger.i('成功移除quarantine属性: $filePath');
      }
    } catch (e) {
      _logger.e('移除quarantine属性时发生错误: $e');
    }
  }

  /// 添加代码签名
  Future<void> _addCodeSignature(String filePath) async {
    try {
      final result = await _processManager.run(['codesign', '--force', '--sign', '-', filePath]);
      if (result.exitCode != 0) {
        _logger.w('添加代码签名失败: ${result.stderr}');
      } else {
        _logger.i('成功添加代码签名: $filePath');
      }
    } catch (e) {
      _logger.e('添加代码签名时发生错误: $e');
    }
  }

  /// 将hdc工具复制到临时目录并返回新路径
  Future<String> _copyToTempAndExecute(String originalPath) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempHdcPath = path.join(tempDir.path, 'hdc_temp_${DateTime.now().millisecondsSinceEpoch}');
      
      // 复制hdc文件到临时目录
      await File(originalPath).copy(tempHdcPath);
      
      // 复制libusb_shared.dylib到同一临时目录
      final originalDir = path.dirname(originalPath);
      final libUsbPath = path.join(originalDir, 'libusb_shared.dylib');
      if (await File(libUsbPath).exists()) {
        final tempLibUsbPath = path.join(tempDir.path, 'libusb_shared.dylib');
        await File(libUsbPath).copy(tempLibUsbPath);
        await _setExecutePermission(tempLibUsbPath);
        await _removeQuarantineAttribute(tempLibUsbPath);
        await _addCodeSignature(tempLibUsbPath);
        _logger.i('已将libusb_shared.dylib复制到临时目录: $tempLibUsbPath');
      }
      
      // 设置执行权限
      await _setExecutePermission(tempHdcPath);
      
      // 移除quarantine属性
      await _removeQuarantineAttribute(tempHdcPath);
      
      // 添加代码签名
      await _addCodeSignature(tempHdcPath);
      
      _logger.i('已将hdc复制到临时目录: $tempHdcPath');
      return tempHdcPath;
    } catch (e) {
      _logger.e('复制hdc到临时目录失败: $e');
      return originalPath; // 失败时返回原路径
    }
  }

  /// 检查设备连接
  Future<List<String>> getConnectedDevices() async {
    if (!_isToolsInstalled) {
      throw Exception('鸿蒙开发工具未安装');
    }

    try {
      // 在macOS上，尝试从临时目录执行hdc
      String hdcPath = _getHdcPath();
      if (_platform.isMacOS) {
        hdcPath = await _copyToTempAndExecute(_getHdcPath());
      }
      
      final result = await _processManager.run([
        hdcPath,
        'list',
        'targets'
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final devices = output
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .where((line) => !line.trim().startsWith('[Empty]'))
            .toList();
        
        _logger.i('发现 ${devices.length} 个连接的设备');
        return devices;
      } else {
        _logger.e('获取设备列表失败: ${result.stderr}');
        return [];
      }
    } catch (e) {
      _logger.e('执行hdc命令失败: $e');
      return [];
    }
  }

  /// 安装HAP包
  Future<bool> installHap(String hapPath, String? deviceId) async {
    if (!_isToolsInstalled) {
      throw Exception('鸿蒙开发工具未安装');
    }

    if (!File(hapPath).existsSync()) {
      throw Exception('HAP文件不存在: $hapPath');
    }

    try {
      _logger.i('开始安装HAP包: $hapPath');
      
      // 在macOS上，尝试从临时目录执行hdc
      String hdcPath = _getHdcPath();
      if (_platform.isMacOS) {
        hdcPath = await _copyToTempAndExecute(_getHdcPath());
      }
      
      // 生成随机临时目录名
      final tempDirName = 'hap_install_${DateTime.now().millisecondsSinceEpoch}';
      final deviceTempPath = 'data/local/tmp/$tempDirName';
      final hapFileName = path.basename(hapPath);
      final deviceHapPath = '$deviceTempPath/$hapFileName';
      
      // 构建基础命令参数
      List<String> getBaseArgs() {
        final args = [hdcPath];
        if (deviceId != null && deviceId.isNotEmpty) {
          args.addAll(['-t', deviceId]);
        }
        return args;
      }
      
      // 步骤1: 关闭应用
      _logger.i('步骤1: 关闭应用');
      final stopArgs = getBaseArgs()..addAll(['shell', 'aa', 'force-stop', 'com.dossen.hap']);
      await _processManager.run(stopArgs);
      
      // 步骤2: 创建临时目录
      _logger.i('步骤2: 创建临时目录 $deviceTempPath');
      final mkdirArgs = getBaseArgs()..addAll(['shell', 'mkdir', deviceTempPath]);
      final mkdirResult = await _processManager.run(mkdirArgs);
      if (mkdirResult.exitCode != 0) {
        _logger.w('创建临时目录失败，可能目录已存在: ${mkdirResult.stderr}');
      }
      
      // 步骤3: 发送HAP文件到临时目录
      _logger.i('步骤3: 发送HAP文件到设备');
      final sendArgs = getBaseArgs()..addAll(['file', 'send', hapPath, deviceHapPath]);
      final sendResult = await _processManager.run(sendArgs);
      if (sendResult.exitCode != 0) {
        _logger.e('发送HAP文件失败: ${sendResult.stderr}');
        // 清理临时目录
        final cleanupArgs = getBaseArgs()..addAll(['shell', 'rm', '-rf', deviceTempPath]);
        await _processManager.run(cleanupArgs);
        return false;
      }
      
      // 步骤4: 安装HAP文件
      _logger.i('步骤4: 安装HAP文件');
      final installArgs = getBaseArgs()..addAll(['shell', 'bm', 'install', '-p', deviceHapPath]);
      final installResult = await _processManager.run(installArgs);
      
      // 步骤5: 删除临时目录
      _logger.i('步骤5: 清理临时目录');
      final cleanupArgs = getBaseArgs()..addAll(['shell', 'rm', '-rf', deviceTempPath]);
      await _processManager.run(cleanupArgs);
      
      if (installResult.exitCode == 0) {
        _logger.i('HAP包安装成功');
        
        // 步骤6: 启动应用
        _logger.i('步骤6: 启动应用');
        final startArgs = getBaseArgs()..addAll(['shell', 'aa', 'start', '-a', 'MainAbility', '-b', 'com.dossen.hap']);
        final startResult = await _processManager.run(startArgs);
        if (startResult.exitCode != 0) {
          _logger.w('启动应用失败: ${startResult.stderr}');
        }
        
        return true;
      } else {
        _logger.e('HAP包安装失败: ${installResult.stderr}');
        return false;
      }
    } catch (e) {
      _logger.e('安装HAP包时发生错误: $e');
      return false;
    }
  }

  /// 卸载应用
  Future<bool> uninstallApp(String packageName, String? deviceId) async {
    if (!_isToolsInstalled) {
      throw Exception('鸿蒙开发工具未安装');
    }

    try {
      _logger.i('开始卸载应用: $packageName');
      
      final args = [_getHdcPath()];
      
      if (deviceId != null && deviceId.isNotEmpty) {
        args.addAll(['-t', deviceId]);
      }
      
      args.addAll(['uninstall', packageName]);

      final result = await _processManager.run(args);

      if (result.exitCode == 0) {
        _logger.i('应用卸载成功');
        return true;
      } else {
        _logger.e('应用卸载失败: ${result.stderr}');
        return false;
      }
    } catch (e) {
      _logger.e('卸载应用时发生错误: $e');
      return false;
    }
  }

  /// 获取已安装的应用列表
  Future<List<String>> getInstalledApps(String? deviceId) async {
    if (!_isToolsInstalled) {
      throw Exception('鸿蒙开发工具未安装');
    }

    try {
      final args = [_getHdcPath()];
      
      if (deviceId != null && deviceId.isNotEmpty) {
        args.addAll(['-t', deviceId]);
      }
      
      args.addAll(['shell', 'bm', 'dump', '-a']);

      final result = await _processManager.run(args);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // 解析应用列表（这里需要根据实际输出格式进行解析）
        final apps = output
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
        
        return apps;
      } else {
        _logger.e('获取应用列表失败: ${result.stderr}');
        return [];
      }
    } catch (e) {
      _logger.e('获取应用列表时发生错误: $e');
      return [];
    }
  }

  /// 检查工具是否已安装
  bool get isToolsInstalled => _isToolsInstalled;

  /// 获取工具路径
  String? get toolsPath => _toolsPath;

  /// 验证HAP文件
  bool isValidHapFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return false;
    
    final extension = path.extension(filePath).toLowerCase();
    return supportedExtensions.contains(extension);
  }

  /// 清理资源
  void dispose() {
    _dio.close();
  }
}