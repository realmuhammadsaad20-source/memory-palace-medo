class Station {
  final String id;
  final String palaceId;
  final String title;
  final String note;
  final int timestampMs;
  final double xRatio;
  final double yRatio;
  final int colorValue;
  final String? linkUrl;

  Station({
    required this.id,
    required this.palaceId,
    required this.title,
    this.note = '',
    required this.timestampMs,
    required this.xRatio,
    required this.yRatio,
    this.colorValue = 0xFFE53935,
    this.linkUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'palaceId': palaceId,
      'title': title,
      'note': note,
      'timestampMs': timestampMs,
      'xRatio': xRatio,
      'yRatio': yRatio,
      'colorValue': colorValue,
      'linkUrl': linkUrl,
    };
  }

  factory Station.fromMap(Map<String, dynamic> map) {
    return Station(
      id: map['id'] as String,
      palaceId: map['palaceId'] as String,
      title: map['title'] as String,
      note: (map['note'] as String?) ?? '',
      timestampMs: map['timestampMs'] as int,
      xRatio: (map['xRatio'] as num).toDouble(),
      yRatio: (map['yRatio'] as num).toDouble(),
      colorValue: map['colorValue'] as int,
      linkUrl: map['linkUrl'] as String?,
    );
  }
}
