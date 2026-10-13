import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../models/palace.dart';
import '../models/station.dart';
import '../services/database_service.dart';
import '../widgets/video_overlay.dart';

class WalkthroughScreen extends StatefulWidget {
  final Palace palace;

  const WalkthroughScreen({Key? key, required this.palace}) : super(key: key);

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  final DatabaseService _db = DatabaseService();
  List<Station> _stations = [];
  VideoPlayerController? _controller;
  bool _isLoading = true;

  Station? _currentActiveStation;
  bool _isAnswerRevealed = false;
  int _lastPausedStationIndex = -1;

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
    _controller!.play();

    // مراقبة الفيديو للتوقف التلقائي (Auto-Pause) عند المحطة
    _controller!.addListener(_checkStationArrival);
  }

  void _checkStationArrival() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_stations.isEmpty) return;

    final currentMs = _controller!.value.position.inMilliseconds;

    for (int i = 0; i < _stations.length; i++) {
      final s = _stations[i];
      final diff = (s.timestampMs - currentMs).abs();

      // إذا وصلنا للمحطة ولم نكن قد توقفنا عندها للتو
      if (diff <= 400 && _lastPausedStationIndex != i) {
        _controller!.pause();
        setState(() {
          _lastPausedStationIndex = i;
          _currentActiveStation = s;
          _isAnswerRevealed = false;
        });
        break;
      }
    }
  }

  void _resumeToNextStation() {
    if (_controller == null) return;
    setState(() {
      _currentActiveStation = null;
      _isAnswerRevealed = false;
    });

    // تحريك طفيف للأمام حتى لا يقف في نفس المحطة فوراً
    final currentPos = _controller!.value.position;
    _controller!.seekTo(currentPos + const Duration(milliseconds: 500));
    _controller!.play();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('جولة: ${widget.palace.name}'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // مشغل الفيديو
                  VideoOverlayWidget(
                    videoPath: widget.palace.videoPath,
                    stations: _stations,
                    isEditMode: false,
                    onControllerReady: _onControllerReady,
                    onStationTap: (s) {
                      setState(() {
                        _currentActiveStation = s;
                        _isAnswerRevealed = true;
                      });
                    },
                  ),

                  // لوحة الاستذكار التفاعلي (Active Recall Panel)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade100,
                      child: _stations.isEmpty
                          ? const Center(
                              child: Text(
                                'لا توجد محطات في هذا القصر بعد.\nيمكنك إضافة محطات عبر شاشة التعديل.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : _currentActiveStation == null
                              ? _buildWalkingState()
                              : _buildStationCard(_currentActiveStation!),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWalkingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.directions_walk_rounded,
            size: 54, color: Colors.indigo),
        const SizedBox(height: 12),
        const Text(
          'أنت تسير الآن داخل قصر الذاكرة...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'سيتوقف الفيديو تلقائياً فور الوصول للمحطة القادمة لاختبار ذاكرتك.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.skip_next),
          label: const Text('انتقال مباشر للمحطة القادمة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            // البحث عن المحطة القادمة
            final currentMs =
                _controller?.value.position.inMilliseconds ?? 0;
            final next = _stations.firstWhere(
              (s) => s.timestampMs > currentMs + 200,
              orElse: () => _stations.first,
            );
            _controller?.seekTo(Duration(milliseconds: next.timestampMs));
          },
        ),
      ],
    );
  }

  Widget _buildStationCard(Station station) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  child: const Icon(Icons.location_on, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'توقف! اختبر ذاكرتك المكانية:',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_isAnswerRevealed) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Text(
                  'هل تتذكر ما هي المعلومة أو الرمز المرتبط بهذا الموضع من الفيديو؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('كشف المعلومة (تأكيد الحفظ)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  setState(() => _isAnswerRevealed = true);
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    if (station.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        station.note,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ],
                    if (station.linkUrl != null &&
                        station.linkUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _openLink(station.linkUrl!),
                        child: Row(
                          children: [
                            const Icon(Icons.link,
                                size: 18, color: Colors.blue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                station.linkUrl!,
                                style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('متابعة السير للمحطة التالية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _resumeToNextStation,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
