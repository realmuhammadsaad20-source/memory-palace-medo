class Station {
  final String id;
  final String palaceId;
  final String title;
  final String note;
  final int timestampMs;
  final double xRatio; // من 0.0 إلى 1.0 بالنسبة لعرض الفيديو
  final double yRatio; // من 0.0 إلى 1.0 بالنسبة لارتفاع الفيديو
  final int colorValue; // لون النقطة التفاعلية
  final String? linkUrl;
  final String? imageUrl;

  Station({
    required this.id,
    required this.palaceId,
    required this.title,
    required this.note,
    required this.timestampMs,
    required this.xRatio,
    required this.yRatio,
    this.colorValue = 0xFF3B82F6, // أزرق افتراضي أنيق
    this.linkUrl,
    this.imageUrl,
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
      'imageUrl': imageUrl,
    };
  }

  factory Station.fromMap(Map<String, dynamic> map) {
    return Station(
      id: map['id'] as String,
      palaceId: map['palaceId'] as String,
      title: map['title'] as String,
      note: map['note'] as String? ?? '',
      timestampMs: map['timestampMs'] as int,
      xRatio: (map['xRatio'] as num).toDouble(),
      yRatio: (map['yRatio'] as num).toDouble(),
      colorValue: map['colorValue'] as int? ?? 0xFF3B82F6,
      linkUrl: map['linkUrl'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
