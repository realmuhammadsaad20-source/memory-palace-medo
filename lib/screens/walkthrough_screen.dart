import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../models/palace.dart';
import '../models/station.dart';
import '../services/database_service.dart';
import '../widgets/video_overlay.dart';

class WalkthroughScreen extends StatefulWidget {
  final Palace palace;

  const WalkthroughScreen({super.key, required this.palace});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final DatabaseService _db = DatabaseService.instance;
  late VideoPlayerController _controller;
  List<Station> _stations = [];
  bool _isInitialized = false;
  Station? _pausedAtStation;
  bool _isRevealed = false;
  String? _lastPausedStationId;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    _stations = await _db.getStations(widget.palace.id);
    _controller = VideoPlayerController.file(File(widget.palace.videoPath));
    await _controller.initialize();
    _controller.addListener(_videoListener);
    await _controller.play();
    if (mounted) setState(() => _isInitialized = true);
  }

  void _videoListener() {
    if (!_controller.value.isPlaying || _stations.isEmpty) return;

    final currentMs = _controller.value.position.inMilliseconds;
    for (final s in _stations) {
      if ((currentMs - s.timestampMs).abs() <= 400 &&
          _lastPausedStationId != s.id) {
        _controller.pause();
        _lastPausedStationId = s.id;
        setState(() {
          _pausedAtStation = s;
          _isRevealed = false;
        });
        break;
      }
    }
  }

  Future<void> _continuePlayback() async {
    if (_pausedAtStation != null) {
      final target = _pausedAtStation!.timestampMs + 500;
      await _controller.seekTo(Duration(milliseconds: target));
    }
    setState(() => _pausedAtStation = null);
    await _controller.play();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.palace.name)),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                VideoOverlay(
                  controller: _controller,
                  stations: _stations,
                  highlightedStationId: _pausedAtStation?.id,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _pausedAtStation == null
                        ? Center(
                            child: Text(
                              'جولة الاستذكار جارية...\nسيتوقف الفيديو تلقائياً عند كل محطة.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                              ),
                            ),
                          )
                        : _buildActiveRecallCard(_pausedAtStation!),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActiveRecallCard(Station station) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(station.colorValue),
                  radius: 12,
                ),
                const SizedBox(width: 8),
                const Text(
                  'اختبار استذكار',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'ما هي المعلومة المربوطة بهذا الموضع؟',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (!_isRevealed)
              FilledButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('كشف الإجابة'),
                onPressed: () => setState(() => _isRevealed = true),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (station.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(station.note),
                    ],
                    if (station.linkUrl != null &&
                        station.linkUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _openLink(station.linkUrl!),
                        child: Text(
                          station.linkUrl!,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('المحطة التالية'),
                onPressed: _continuePlayback,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
