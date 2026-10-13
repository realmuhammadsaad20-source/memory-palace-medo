import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/palace.dart';
import '../models/station.dart';
import '../services/database_service.dart';
import '../widgets/add_station_dialog.dart';
import '../widgets/video_overlay.dart';

class EditorScreen extends StatefulWidget {
  final Palace palace;

  const EditorScreen({super.key, required this.palace});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final DatabaseService _db = DatabaseService.instance;
  late VideoPlayerController _controller;
  List<Station> _stations = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    _stations = await _db.getStations(widget.palace.id);
    _controller = VideoPlayerController.file(File(widget.palace.videoPath));
    await _controller.initialize();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() => _isInitialized = true);
  }

  Future<void> _reloadStations() async {
    final list = await _db.getStations(widget.palace.id);
    setState(() => _stations = list);
  }

  Future<void> _onTapVideo(double xRatio, double yRatio) async {
    await _controller.pause();
    final currentMs = _controller.value.position.inMilliseconds;

    if (!mounted) return;
    final newStation = await showDialog<Station>(
      context: context,
      builder: (_) => AddStationDialog(
        palaceId: widget.palace.id,
        timestampMs: currentMs,
        xRatio: xRatio,
        yRatio: yRatio,
      ),
    );

    if (newStation != null) {
      await _db.insertStation(newStation);
      await _reloadStations();
    }
  }

  String _formatTime(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final tenths = ((ms % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$tenths';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.palace.name),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                VideoOverlay(
                  controller: _controller,
                  stations: _stations,
                  onTap: _onTapVideo,
                ),
                _buildControls(),
                const Divider(height: 1),
                Expanded(child: _buildStationList()),
              ],
            ),
    );
  }

  Widget _buildControls() {
    final position = _controller.value.position.inMilliseconds;
    final duration = _controller.value.duration.inMilliseconds;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
              Expanded(
                child: Slider(
                  value: duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0,
                  onChanged: (val) {
                    _controller.seekTo(Duration(milliseconds: (val * duration).toInt()));
                  },
                ),
              ),
              Text(
                '${_formatTime(position)} / ${_formatTime(duration)}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
          const Text(
            'أوقف الفيديو عند المعلم وانقر على الفيديو لإضافة محطة',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStationList() {
    if (_stations.isEmpty) {
      return const Center(child: Text('لم تضف أي محطة بعد. انقر على الفيديو.'));
    }

    return ListView.builder(
      itemCount: _stations.length,
      itemBuilder: (context, index) {
        final s = _stations[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(s.colorValue),
            radius: 12,
          ),
          title: Text(s.title),
          subtitle: Text('${_formatTime(s.timestampMs)} - ${s.note}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _db.deleteStation(s.id);
              await _reloadStations();
            },
          ),
          onTap: () {
            _controller.seekTo(Duration(milliseconds: s.timestampMs));
          },
        );
      },
    );
  }
}
