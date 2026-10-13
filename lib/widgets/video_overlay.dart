import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/station.dart';

class VideoOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final List<Station> stations;
  final void Function(double xRatio, double yRatio)? onTap;
  final String? highlightedStationId;

  const VideoOverlay({
    super.key,
    required this.controller,
    required this.stations,
    this.onTap,
    this.highlightedStationId,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(controller),
              if (onTap != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final xRatio =
                        (details.localPosition.dx / width).clamp(0.0, 1.0);
                    final yRatio =
                        (details.localPosition.dy / height).clamp(0.0, 1.0);
                    onTap!(xRatio, yRatio);
                  },
                ),
              ...stations.map((s) {
                final isHighlighted = s.id == highlightedStationId;
                return Positioned(
                  left: s.xRatio * width - 12,
                  top: s.yRatio * height - 12,
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isHighlighted ? 32 : 24,
                      height: isHighlighted ? 32 : 24,
                      decoration: BoxDecoration(
                        color: Color(s.colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
