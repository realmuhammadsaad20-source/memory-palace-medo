import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/palace.dart';
import '../services/database_service.dart';
import 'editor_screen.dart';
import 'walkthrough_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<Palace> _palaces = [];
  Map<String, int> _stationCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPalaces();
  }

  Future<void> _loadPalaces() async {
    setState(() => _isLoading = true);
    final list = await _db.getPalaces();
    final counts = <String, int>{};
    for (final p in list) {
      counts[p.id] = await _db.getStationCount(p.id);
    }
    setState(() {
      _palaces = list;
      _stationCounts = counts;
      _isLoading = false;
    });
  }

  Future<void> _showCreatePalaceDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قصر ذاكرة جديد'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم القصر',
                  hintText: 'مثال: تاريخ الطب - الفصل الأول',
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              await _pickVideoAndCreate(
                nameController.text.trim(),
                descController.text.trim(),
              );
            },
            child: const Text('اختيار فيديو'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVideoAndCreate(String name, String description) async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final id = Uuid().v4();
    final targetDir = Directory('${appDir.path}/palace_videos');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final targetPath = '${targetDir.path}/palace_$id.mp4';
    await File(picked.path).copy(targetPath);

    final palace = Palace(
      id: id,
      name: name,
      description: description,
      videoPath: targetPath,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _db.insertPalace(palace);
    await _loadPalaces();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditorScreen(palace: palace)),
      ).then((_) => _loadPalaces());
    }
  }

  Future<void> _confirmDelete(Palace palace) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف قصر "${palace.name}" وجميع محطاته؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final f = File(palace.videoPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      await _db.deletePalace(palace.id);
      await _loadPalaces();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ميموري بالاس ميدو',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _palaces.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _palaces.length,
                  itemBuilder: (context, index) {
                    final p = _palaces[index];
                    final count = _stationCounts[p.id] ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Badge(
                                  label: Text('$count محطة'),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                            if (p.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                p.description,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Theme.of(context).colorScheme.error,
                                  onPressed: () => _confirmDelete(p),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('المحطات'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditorScreen(palace: p),
                                      ),
                                    ).then((_) => _loadPalaces());
                                  },
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('استذكار'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            WalkthroughScreen(palace: p),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePalaceDialog,
        icon: const Icon(Icons.add),
        label: const Text('قصر جديد'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد قصور ذاكرة بعد',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على زر "قصر جديد" لاختيار فيديو والبدء في ربط المحطات والمعلومات.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
