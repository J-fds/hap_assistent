/// 应用模型类
class App {
  final String bundleName;
  final String appName;
  final String version;
  final String? icon;
  final bool isInstalled;
  final DateTime? installTime;
  final int? size;

  App({
    required this.bundleName,
    required this.appName,
    required this.version,
    this.icon,
    required this.isInstalled,
    this.installTime,
    this.size,
  });

  /// 获取应用显示名称
  String get displayName {
    return '$appName ($version)';
  }

  /// 获取应用大小的可读格式
  String get sizeFormatted {
    if (size == null) return '未知';
    
    final sizeValue = size!;
    if (sizeValue < 1024) {
      return '${sizeValue}B';
    } else if (sizeValue < 1024 * 1024) {
      return '${(sizeValue / 1024).toStringAsFixed(1)}KB';
    } else if (sizeValue < 1024 * 1024 * 1024) {
      return '${(sizeValue / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(sizeValue / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 获取安装状态文本
  String get installStatus {
    return isInstalled ? '已安装' : '未安装';
  }

  /// 获取安装时间的格式化字符串
  String get installTimeFormatted {
    if (installTime == null) return '未知';
    
    final time = installTime!;
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
           '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 复制应用信息并修改部分属性
  App copyWith({
    String? bundleName,
    String? appName,
    String? version,
    String? icon,
    bool? isInstalled,
    DateTime? installTime,
    int? size,
  }) {
    return App(
      bundleName: bundleName ?? this.bundleName,
      appName: appName ?? this.appName,
      version: version ?? this.version,
      icon: icon ?? this.icon,
      isInstalled: isInstalled ?? this.isInstalled,
      installTime: installTime ?? this.installTime,
      size: size ?? this.size,
    );
  }

  @override
  String toString() {
    return 'App(bundleName: $bundleName, appName: $appName, version: $version, isInstalled: $isInstalled, size: $sizeFormatted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is App &&
        other.bundleName == bundleName &&
        other.appName == appName &&
        other.version == version &&
        other.icon == icon &&
        other.isInstalled == isInstalled &&
        other.installTime == installTime &&
        other.size == size;
  }

  @override
  int get hashCode {
    return Object.hash(bundleName, appName, version, icon, isInstalled, installTime, size);
  }
}