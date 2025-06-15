/// 包文件模型类
class PackageFile {
  final String name;
  final String path;
  final String type;
  final DateTime createdTime;
  final int size;

  PackageFile({
    required this.name,
    required this.path,
    required this.type,
    required this.createdTime,
    required this.size,
  });

  /// 获取文件大小的可读格式
  String get sizeFormatted {
    if (size < 1024) {
      return '${size}B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)}KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 获取文件扩展名
  String get extension {
    final lastDot = name.lastIndexOf('.');
    if (lastDot != -1 && lastDot < name.length - 1) {
      return name.substring(lastDot + 1).toLowerCase();
    }
    return '';
  }

  /// 判断是否为HAP文件
  bool get isHap => type == 'hap' || extension == 'hap';

  /// 判断是否为APP文件
  bool get isApp => type == 'app' || extension == 'app';

  @override
  String toString() {
    return 'PackageFile(name: $name, type: $type, size: $sizeFormatted, createdTime: $createdTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PackageFile &&
        other.name == name &&
        other.path == path &&
        other.type == type &&
        other.createdTime == createdTime &&
        other.size == size;
  }

  @override
  int get hashCode {
    return Object.hash(name, path, type, createdTime, size);
  }
}