import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import '../models/package_file.dart';

/// 包文件服务类
/// 负责从打包机获取HAP/APP包文件列表
class PackageService {
  static final PackageService _instance = PackageService._internal();
  factory PackageService() => _instance;
  PackageService._internal();

  final Logger _logger = Logger();
  final Dio _dio = Dio();

  /// 从打包机获取包文件列表
  /// [serverIp] 打包机IP地址
  /// [folderPath] 包文件目录路径
  Future<List<PackageFile>> fetchPackageFiles(String serverIp, String folderPath) async {
    try {
      _logger.i('正在从打包机获取包文件列表...');
      _logger.i('服务器: $serverIp');
      _logger.i('路径: $folderPath');

      // 构建API请求URL
      final apiUrl = 'http://$serverIp:8080/api/packages';
      
      // 发送HTTP请求获取包文件列表
      final response = await _dio.get(
        apiUrl,
        queryParameters: {
          'path': folderPath,
          'extensions': 'hap,app', // 只获取HAP和APP文件
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          final files = data['files'] as List<dynamic>? ?? [];
          
          final packageFiles = files.map((fileData) {
            return PackageFile(
              name: fileData['name'] as String,
              path: fileData['path'] as String,
              type: _getFileType(fileData['name'] as String),
              createdTime: DateTime.parse(fileData['createdTime'] as String),
              size: fileData['size'] as int,
            );
          }).toList();

          // 按创建时间排序（最新的在前）
          packageFiles.sort((a, b) => b.createdTime.compareTo(a.createdTime));
          
          _logger.i('成功获取到 ${packageFiles.length} 个包文件');
          return packageFiles;
        } else {
          throw Exception('服务器返回错误: ${data['message'] ?? '未知错误'}');
        }
      } else {
        throw Exception('HTTP请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = '连接超时，请检查网络连接和服务器地址';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = '接收数据超时';
          break;
        case DioExceptionType.connectionError:
          errorMessage = '无法连接到打包机，请检查IP地址和网络连接';
          break;
        default:
          errorMessage = '网络请求失败: ${e.message}';
      }
      _logger.e('获取包文件列表失败: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      _logger.e('获取包文件列表失败: $e');
      throw Exception('获取包文件列表失败: $e');
    }
  }

  /// 检查打包机连接状态
  Future<bool> checkConnection(String serverIp) async {
    try {
      final apiUrl = 'http://$serverIp:8080/api/health';
      
      final response = await _dio.get(
        apiUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.w('打包机连接检查失败: $e');
      return false;
    }
  }

  /// 获取文件类型
  String _getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.hap':
        return 'hap';
      case '.app':
        return 'app';
      default:
        return 'unknown';
    }
  }

  /// 下载包文件到本地
  Future<String> downloadPackageFile(
    String serverIp,
    String remotePath,
    String localDir,
    {Function(double)? onProgress}
  ) async {
    try {
      final fileName = path.basename(remotePath);
      final localPath = path.join(localDir, fileName);
      
      // 确保本地目录存在
      await Directory(localDir).create(recursive: true);
      
      final downloadUrl = 'http://$serverIp:8080/api/download';
      
      await _dio.download(
        downloadUrl,
        localPath,
        queryParameters: {'path': remotePath},
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 10), // 下载超时时间
        ),
      );
      
      _logger.i('包文件下载完成: $localPath');
      return localPath;
    } catch (e) {
      _logger.e('下载包文件失败: $e');
      throw Exception('下载包文件失败: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _dio.close();
  }
}