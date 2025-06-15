/// 设备模型类
class Device {
  final String id;
  final String name;
  final String type;
  final bool isConnected;
  final String? ipAddress;
  final int? port;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.isConnected,
    this.ipAddress,
    this.port,
  });

  /// 获取设备显示名称
  String get displayName {
    if (ipAddress != null) {
      return '$name ($ipAddress)';
    }
    return name;
  }

  /// 判断是否为网络设备
  bool get isNetworkDevice => ipAddress != null;

  /// 判断是否为USB设备
  bool get isUsbDevice => !isNetworkDevice;

  /// 获取连接状态文本
  String get connectionStatus {
    return isConnected ? '已连接' : '未连接';
  }

  /// 复制设备信息并修改部分属性
  Device copyWith({
    String? id,
    String? name,
    String? type,
    bool? isConnected,
    String? ipAddress,
    int? port,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
    );
  }

  @override
  String toString() {
    return 'Device(id: $id, name: $name, type: $type, isConnected: $isConnected, ipAddress: $ipAddress, port: $port)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.isConnected == isConnected &&
        other.ipAddress == ipAddress &&
        other.port == port;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, type, isConnected, ipAddress, port);
  }
}