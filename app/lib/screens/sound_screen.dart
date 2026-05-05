import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ble_service.dart';
import '../models/settings_model.dart';
import '../models/device_model.dart';

class SoundScreen extends ConsumerWidget {
  const SoundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bluetoothStateProvider);
    final deviceStatus = ref.watch(deviceStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音效管理'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前音效显示
            _buildCurrentSoundCard(context, deviceStatus, bleState),
            const SizedBox(height: 24),
            
            // 音效列表标题
            const Text(
              '选择报警音效',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 音效列表
            Expanded(
              child: ListView.builder(
                itemCount: SoundEffect.presets.length,
                itemBuilder: (context, index) {
                  final effect = SoundEffect.presets[index];
                  final isSelected = deviceStatus.currentSoundEffect == effect.index;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? effect.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: effect.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          effect.icon,
                          color: effect.color,
                        ),
                      ),
                      title: Text(
                        effect.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(effect.description),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: effect.color)
                          : null,
                      onTap: bleState.isConnected
                          ? () async {
                              await ref
                                  .read(bleServiceProvider)
                                  .setSoundEffect(effect.index);
                            }
                          : null,
                    ),
                  );
                },
              ),
            ),
            
            // 自定义上传按钮
            if (bleState.isConnected)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showUploadDialog(context);
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('上传自定义音效'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSoundCard(
    BuildContext context,
    DeviceStatus status,
    BleState bleState,
  ) {
    final currentEffect = SoundEffect.presets.length > status.currentSoundEffect
        ? SoundEffect.presets[status.currentSoundEffect]
        : SoundEffect.presets[0];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              currentEffect.color.withOpacity(0.1),
              currentEffect.color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: currentEffect.color,
                ),
                const SizedBox(width: 8),
                const Text(
                  '当前音效',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: currentEffect.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    currentEffect.icon,
                    color: currentEffect.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bleState.isConnected
                            ? currentEffect.name
                            : '未连接设备',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bleState.isConnected
                            ? currentEffect.description
                            : '请先连接设备',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('上传自定义音效'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('支持格式: MP3, WAV'),
            SizedBox(height: 8),
            Text('最大文件大小: 5MB'),
            SizedBox(height: 16),
            Text('请将音频文件通过USB拷贝到设备存储中'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('功能开发中...')),
              );
            },
            child: const Text('选择文件'),
          ),
        ],
      ),
    );
  }
}
