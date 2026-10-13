class Palace {
  final String id;
  final String name;
  final String description;
  final String videoPath;
  final String createdAt;

  Palace({
    required this.id,
    required this.name,
    this.description = '',
    required this.videoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'videoPath': videoPath,
      'createdAt': createdAt,
    };
  }

  factory Palace.fromMap(Map<String, dynamic> map) {
    return Palace(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      videoPath: map['videoPath'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}
