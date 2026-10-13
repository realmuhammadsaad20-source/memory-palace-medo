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
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  List<Palace> _palaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPalaces();
  }

  Future<void> _loadPalaces() async {
    setState(() => _isLoading = true);
    final list = await _db.getPalaces();
    setState(() {
      _palaces = list;
      _isLoading = false;
    });
  }

  Future<void> _createPalaceDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.castle_rounded, color: Colors.indigo),
              SizedBox(width: 8),
              Text('إنشاء قصر ذاكرة جديد'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم القصر',
                  hintText: 'مثال: قصر التاريخ - الغرفة الأولى',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'وصف أو ملاحظات (اختياري)',
                  hintText: 'ما هي المعلومات المحفوظة هنا؟',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(ctx);
                _pickAndSaveVideo(name, descController.text.trim());
              },
              child: const Text('اختيار الفيديو ومتابعة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSaveVideo(String name, String description) async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video == null) return;

    // حل مشكلة اختفاء الفيديو: نسخه للمجلد الداخلي الخاص بالتطبيق
    final appDir = await getApplicationDocumentsDirectory();
    final videoId = const Uuid().v4();
    final targetPath = '${appDir.path}/palace_video_$videoId.mp4';
    final savedVideo = await File(video.path).copy(targetPath);

    final palace = Palace(
      id: videoId,
      name: name,
      description: description,
      videoPath: savedVideo.path,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _db.insertPalace(palace);
    await _loadPalaces();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditorScreen(palace: palace),
        ),
      ).then((_) => _loadPalaces());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'ميموري بالاس ميدو',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _palaces.isEmpty
                ? _buildEmptyState()
                : _buildPalacesList(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createPalaceDialog,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.video_call_rounded),
          label: const Text('قصر جديد بالفيديو'),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                size: 80,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'أهلاً بك في ميموري بالاس ميدو',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'لا توجد قصور ذاكرة حتى الآن.\nاضغط على الزر بالأسفل لاختيار فيديو من هاتفك وبناء قصرك الأول!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPalacesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _palaces.length,
      itemBuilder: (context, index) {
        final palace = _palaces[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        palace.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(palace),
                    ),
                  ],
                ),
                if (palace.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    palace.description,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_fill, size: 20),
                        label: const Text('بدء الاستذكار'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WalkthroughScreen(palace: palace),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_location_alt, size: 20),
                      label: const Text('تعديل المحطات'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo,
                        side: const BorderSide(color: Colors.indigo),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditorScreen(palace: palace),
                          ),
                        ).then((_) => _loadPalaces());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(Palace palace) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف قصر "${palace.name}" وجميع محطاته؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _db.deletePalace(palace.id);
                _loadPalaces();
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
