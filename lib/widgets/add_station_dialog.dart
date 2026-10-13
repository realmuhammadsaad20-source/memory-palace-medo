import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/station.dart';

class AddStationDialog extends StatefulWidget {
  final String palaceId;
  final int timestampMs;
  final double xRatio;
  final double yRatio;
  final Station? initialStation;

  const AddStationDialog({
    Key? key,
    required this.palaceId,
    required this.timestampMs,
    required this.xRatio,
    required this.yRatio,
    this.initialStation,
  }) : super(key: key);

  @override
  State<AddStationDialog> createState() => _AddStationDialogState();
}

class _AddStationDialogState extends State<AddStationDialog> {
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late TextEditingController _linkController;
  late int _selectedColor;

  final List<int> _colors = [
    0xFF3B82F6, // أزرق
    0xFF10B981, // أخضر
    0xFFEF4444, // أحمر
    0xFFF59E0B, // كهرماني
    0xFF8B5CF6, // بنفسجي
  ];

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialStation?.title ?? '');
    _noteController =
        TextEditingController(text: widget.initialStation?.note ?? '');
    _linkController =
        TextEditingController(text: widget.initialStation?.linkUrl ?? '');
    _selectedColor = widget.initialStation?.colorValue ?? _colors.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (widget.timestampMs / 1000).toStringAsFixed(1);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.add_location_alt_rounded, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(widget.initialStation == null
                ? 'إضافة محطة عند ($seconds ث)'
                : 'تعديل المحطة'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان المعلومة / الكلمة المفتاحية',
                  hintText: 'مثال: تاريخ معركة حطين',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'الملاحظة / التفاصيل الكاملة',
                  hintText: 'اكتب الشرح أو ما تريد تذكره هنا...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'رابط خارجي (اختياري)',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختر لون علامة المحطة:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _colors.map((c) {
                  final isSelected = c == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (_titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى كتابة عنوان للمحطة')),
                );
                return;
              }

              final station = Station(
                id: widget.initialStation?.id ?? Uuid().v4(),
                palaceId: widget.palaceId,
                title: _titleController.text.trim(),
                note: _noteController.text.trim(),
                timestampMs: widget.timestampMs,
                xRatio: widget.xRatio,
                yRatio: widget.yRatio,
                colorValue: _selectedColor,
                linkUrl: _linkController.text.trim().isEmpty
                    ? null
                    : _linkController.text.trim(),
              );

              Navigator.pop(context, station);
            },
            child: const Text('حفظ المحطة'),
          ),
        ],
      ),
    );
  }
}
