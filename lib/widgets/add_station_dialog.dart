import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/station.dart';

class AddStationDialog extends StatefulWidget {
  final String palaceId;
  final int timestampMs;
  final double xRatio;
  final double yRatio;

  const AddStationDialog({
    super.key,
    required this.palaceId,
    required this.timestampMs,
    required this.xRatio,
    required this.yRatio,
  });

  @override
  State<AddStationDialog> createState() => _AddStationDialogState();
}

class _AddStationDialogState extends State<AddStationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _linkController = TextEditingController();

  static const List<int> _colors = [
    0xFFE53935, // أحمر
    0xFF1E88E5, // أزرق
    0xFF43A047, // أخضر
    0xFFFB8C00, // برتقالي
    0xFF8E24AA, // بنفسجي
  ];

  int _selectedColor = _colors[0];

  @override
  Widget build(BuildContext context) {
    final seconds = (widget.timestampMs / 1000).toStringAsFixed(1);

    return AlertDialog(
      title: Text('إضافة محطة ($seconds ث)'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'العنوان / المفهوم'),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'العنوان مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'ملاحظات وتفاصيل'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(labelText: 'رابط خارجي (اختياري)'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _colors.map((c) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: CircleAvatar(
                      backgroundColor: Color(c),
                      radius: 16,
                      child: _selectedColor == c
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final station = Station(
              id: Uuid().v4(),
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
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
