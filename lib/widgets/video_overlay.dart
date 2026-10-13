import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/station.dart';

class VideoOverlayWidget extends StatefulWidget {
  final String videoPath;
  final List<Station> stations;
  final bool isEditMode;
  final Function(double xRatio, double yRatio, int timestampMs)? onAddPoint;
  final Function(Station station)? onStationTap;
  final Function(VideoPlayerController controller)? onControllerReady;

  const VideoOverlayWidget({
    Key? key,
    required this.videoPath,
    required this.stations,
    this.isEditMode = false,
    this.onAddPoint,
    this.onStationTap,
    this.onControllerReady,
  }) : super(key: key);

  @override
  State<VideoOverlayWidget> createState() => _VideoOverlayWidgetState();
}

class _VideoOverlayWidgetState extends State<VideoOverlayWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final file = File(widget.videoPath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'ملف الفيديو غير موجود أو تم نقله';
        });
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      _controller!.setLooping(true);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.onControllerReady != null) {
          widget.onControllerReady!(_controller!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في تشغيل الفيديو: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        height: 250,
        color: Colors.black87,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: 250,
        color: Colors.black,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.indigoAccent),
            SizedBox(height: 12),
            Text(
              'جاري تجهيز مشغل الفيديو...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              // طبقة الفيديو
              VideoPlayer(_controller!),

              // طبقة استشعار اللمس في وضع التحرير
              if (widget.isEditMode)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    final localPos = details.localPosition;
                    final xRatio = (localPos.dx / width).clamp(0.0, 1.0);
                    final yRatio = (localPos.dy / height).clamp(0.0, 1.0);
                    final currentMs =
                        _controller!.value.position.inMilliseconds;

                    if (widget.onAddPoint != null) {
                      widget.onAddPoint!(xRatio, yRatio, currentMs);
                    }
                  },
                ),

              // طبقة رسم النقاط التفاعلية (Stations Markers)
              ValueListenableBuilder(
                valueListenable: _controller!,
                builder: (context, VideoPlayerValue value, child) {
                  final currentMs = value.position.inMilliseconds;

                  return Stack(
                    children: widget.stations.map((station) {
                      // في وضع التحرير نعرض المحطات القريبة من الثانية الحالية
                      // في وضع العرض تظهر المحطة عندما يكون الفيديو قريباً منها (بفارق ثانيتين مثلاً)
                      final timeDiff = (station.timestampMs - currentMs).abs();
                      final isVisible = widget.isEditMode || (timeDiff <= 1500);

                      if (!isVisible) return const SizedBox.shrink();

                      return Positioned(
                        left: station.xRatio * width - 20,
                        top: station.yRatio * height - 20,
                        child: GestureDetector(
                          onTap: () {
                            if (widget.onStationTap != null) {
                              widget.onStationTap!(station);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(station.colorValue).withOpacity(0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
