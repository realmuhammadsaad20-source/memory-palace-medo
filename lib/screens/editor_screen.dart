import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/palace.dart';
import '../models/station.dart';
import '../services/database_service.dart';
import '../widgets/add_station_dialog.dart';
import '../widgets/video_overlay.dart';

class EditorScreen extends StatefulWidget {
  final Palace palace;

  const EditorScreen({Key? key, required this.palace}) : super(key: key);

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final DatabaseService _db = DatabaseService();
  List<Station> _stations = [];
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  double _sliderValue = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    final list = await _db.getStationsForPalace(widget.palace.id);
    if (mounted) {
      setState(() {
        _stations = list;
        _isLoading = false;
      });
    }
  }

  void _onControllerReady(VideoPlayerController ctrl) {
    _controller = ctrl;
    _controller!.addListener(() {
      if (mounted && _controller!.value.isInitialized) {
        setState(() {
          _isPlaying = _controller!.value.isPlaying;
          final duration = _controller!.value.duration.inMilliseconds;
          if (duration > 0) {
            _sliderValue =
                _controller!.value.position.inMilliseconds / duration;
          }
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _seekToPercent(double percent) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final targetMs =
        (_controller!.value.duration.inMilliseconds * percent).round();
    _controller!.seekTo(Duration(milliseconds: targetMs));
  }

  Future<void> _addNewStation(
      double xRatio, double yRatio, int timestampMs) async {
    // إيقاف الفيديو أثناء الإضافة
    _controller?.pause();

    final Station? created = await showDialog<Station>(
      context: context,
      builder: (_) => AddStationDialog(
        palaceId: widget.palace.id,
        timestampMs: timestampMs,
        xRatio: xRatio,
        yRatio: yRatio,
      ),
    );

    if (created != null) {
      await _db.insertStation(created);
      await _loadStations();
    }
  }

  void _seekToStation(Station s) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _controller!.seekTo(Duration(milliseconds: s.timestampMs));
    _controller!.pause();
  }

  Future<void> _deleteStation(Station s) async {
    await _db.deleteStation(s.id);
    await _loadStations();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.palace.name),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  '${_stations.length} محطة',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // مساحة إرشادية للمستخدم
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'أوقف الفيديو عند اللحظة المطلوبة، ثم انقر في أي مكان على الفيديو لتثبيت محطة!',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            // مشغل الفيديو التفاعلي
            VideoOverlayWidget(
              videoPath: widget.palace.videoPath,
              stations: _stations,
              isEditMode: true,
              onControllerReady: _onControllerReady,
              onAddPoint: _addNewStation,
              onStationTap: _seekToStation,
            ),

            // شريط التحكم بالفيديو الدقيق
            Container(
              color: Colors.grey.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  Expanded(
                    child: Slider(
                      value: _sliderValue.clamp(0.0, 1.0),
                      activeColor: Colors.indigoAccent,
                      inactiveColor: Colors.white24,
                      onChanged: (val) {
                        setState(() => _sliderValue = val);
                        _seekToPercent(val);
                      },
                    ),
                  ),
                  if (_controller != null && _controller!.value.isInitialized)
                    Text(
                      '${(_controller!.value.position.inSeconds)} ث',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                ],
              ),
            ),

            // قائمة المحطات المضافة في هذا القصر
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'المحطات المحفوظة في هذا القصر:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _stations.isEmpty
                      ? const Center(
                          child: Text(
                            'لم تتم إضافة أي محطات بعد.\nانقر على شاشة الفيديو أعلاه لإضافة أول محطة.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _stations.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final station = _stations[idx];
                            final timeSec =
                                (station.timestampMs / 1000).toStringAsFixed(1);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(station.colorValue),
                                child: const Icon(Icons.pin_drop,
                                    color: Colors.white, size: 20),
                              ),
                              title: Text(
                                station.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'الوقت: $timeSec ثانية | ${station.note}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye,
                                        color: Colors.indigo),
                                    tooltip: 'انتقال لهذه اللحظة',
                                    onPressed: () => _seekToStation(station),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    onPressed: () => _deleteStation(station),
                                  ),
                                ],
                              ),
                              onTap: () => _seekToStation(station),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
