import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class LogViewer extends StatefulWidget {
  const LogViewer({super.key});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // 自动滚动到底部
        if (_autoScroll && provider.logs.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '运行日志',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Row(
                    children: [
                      // 自动滚动开关
                      Row(
                        children: [
                          Switch(
                            value: _autoScroll,
                            onChanged: (value) {
                              setState(() {
                                _autoScroll = value;
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          const Text('自动滚动'),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // 复制日志按钮
                      IconButton(
                        onPressed: provider.logs.isEmpty ? null : () {
                          _copyLogs(provider.logs);
                        },
                        icon: const Icon(Icons.copy),
                        tooltip: '复制日志',
                      ),
                      // 清除日志按钮
                      IconButton(
                        onPressed: provider.logs.isEmpty ? null : () {
                          _showClearDialog(context, provider);
                        },
                        icon: const Icon(Icons.clear_all),
                        tooltip: '清除日志',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 日志统计信息
              _buildLogStats(context, provider),
              const SizedBox(height: 16),
              
              // 日志内容
              Expanded(
                child: _buildLogContent(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogStats(BuildContext context, AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '日志统计',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            _buildStatItem('总计', provider.logs.length.toString()),
            const SizedBox(width: 16),
            _buildStatItem('状态', provider.statusMessage),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLogContent(BuildContext context, AppProvider provider) {
    if (provider.logs.isEmpty) {
      return _buildEmptyState(context);
    }

    return Card(
      child: Column(
        children: [
          // 日志头部
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  '控制台输出',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.logs.length} 条记录',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 日志列表
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: provider.logs.length,
                itemBuilder: (context, index) {
                  return _buildLogItem(provider.logs[index], index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                '暂无日志记录',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '应用运行时的日志信息将显示在这里',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(String log, int index) {
    final isEven = index % 2 == 0;
    final logLevel = _getLogLevel(log);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isEven 
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border(
          left: BorderSide(
            color: _getLogLevelColor(logLevel),
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 行号
          Container(
            width: 40,
            alignment: Alignment.centerRight,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 日志级别图标
          Icon(
            _getLogLevelIcon(logLevel),
            size: 14,
            color: _getLogLevelColor(logLevel),
          ),
          const SizedBox(width: 8),
          // 日志内容
          Expanded(
            child: SelectableText(
              log,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.3,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LogLevel _getLogLevel(String log) {
    final lowerLog = log.toLowerCase();
    if (lowerLog.contains('error') || lowerLog.contains('错误') || lowerLog.contains('失败')) {
      return LogLevel.error;
    } else if (lowerLog.contains('warning') || lowerLog.contains('warn') || lowerLog.contains('警告')) {
      return LogLevel.warning;
    } else if (lowerLog.contains('success') || lowerLog.contains('成功') || lowerLog.contains('完成')) {
      return LogLevel.success;
    } else {
      return LogLevel.info;
    }
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.success:
        return Colors.green;
      case LogLevel.info:
      default:
        return Colors.blue;
    }
  }

  IconData _getLogLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.warning:
        return Icons.warning_amber_outlined;
      case LogLevel.success:
        return Icons.check_circle_outline;
      case LogLevel.info:
      default:
        return Icons.info_outline;
    }
  }

  void _copyLogs(List<String> logs) {
    final logText = logs.join('\n');
    Clipboard.setData(ClipboardData(text: logText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('日志已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除日志'),
        content: const Text('确定要清除所有日志记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.clearLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('日志已清除'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}

enum LogLevel {
  info,
  warning,
  error,
  success,
}