import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../../shared/animations/tap_scale.dart';
import '../../../../shared/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/lesson_topic_artwork.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../lessons/data/models/lesson.dart';
import '../../../lessons/providers/lesson_providers.dart';
import '../../../notifications/providers/notification_providers.dart';

String lessonImageLabel(String value) {
  final normalized = normalizeLessonImagePath(value);
  if (normalized.isEmpty) {
    return 'No image selected';
  }

  final uri = Uri.tryParse(normalized);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last;
  }

  final segments = normalized.split('/');
  if (segments.isNotEmpty) {
    return segments.last;
  }
  return normalized;
}

class ManageLessonsScreen extends ConsumerStatefulWidget {
  const ManageLessonsScreen({super.key});

  @override
  ConsumerState<ManageLessonsScreen> createState() =>
      _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends ConsumerState<ManageLessonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openLessonSheet(
    BuildContext context,
    WidgetRef ref, {
    Lesson? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LessonEditorSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: lessonsAsync.when(
        data: (lessons) {
          final filtered = lessons.where((item) {
            final key = _search.toLowerCase();
            if (key.isEmpty) {
              return true;
            }
            return item.title.toLowerCase().contains(key) ||
                item.topic.toLowerCase().contains(key) ||
                item.difficulty.toLowerCase().contains(key);
          }).toList();

          final publishedCount = lessons
              .where((item) => item.isPublished)
              .length;
          final draftsCount = lessons.length - publishedCount;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0E4AB5), Color(0xFF0F7AE5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lesson Upload Center',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Create and publish lessons for students with smooth, real-time updates.',
                        style: TextStyle(
                          color: Color(0xFFE0EBFF),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _StatPill(
                            icon: Icons.menu_book_rounded,
                            label: '$publishedCount Published',
                          ),
                          _StatPill(
                            icon: Icons.edit_note_rounded,
                            label: '$draftsCount Drafts',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search your lessons...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    'Your Lessons',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _openLessonSheet(context, ref),
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Upload Lesson'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No lessons found.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final lesson = filtered[index];
                          return FadeSlideIn(
                            delayMs: 40 + (index * 35),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                title: Text(lesson.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${lesson.topic} - ${lesson.difficulty} - ${lesson.estimatedMinutes} min',
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Image: ${lessonImageLabel(lesson.bannerUrl)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                leading: _LessonListLeading(
                                  lessonId: lesson.lessonId,
                                  imageUrl: lesson.bannerUrl,
                                  isPublished: lesson.isPublished,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _openLessonSheet(
                                        context,
                                        ref,
                                        existing: lesson,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      onPressed: () => ConfirmationDialog.show(
                                        context,
                                        title: 'Delete Lesson',
                                        message:
                                            'Delete ${lesson.title}? This action cannot be undone.',
                                        confirmLabel: 'Delete',
                                        onConfirm: () async {
                                          await ref
                                              .read(lessonRepositoryProvider)
                                              .deleteLesson(lesson.lessonId);
                                          ref.invalidate(lessonsProvider);
                                          ref.invalidate(lessonsStreamProvider);
                                          ref.invalidate(
                                            studentLessonsProvider,
                                          );
                                          ref.invalidate(
                                            studentLessonsStreamProvider,
                                          );
                                        },
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(label: 'Loading lessons...'),
        error: (_, __) => const Center(child: Text('Failed to load lessons.')),
      ),
    );
  }
}

class _LessonEditorSheet extends ConsumerStatefulWidget {
  const _LessonEditorSheet({this.existing});

  final Lesson? existing;

  @override
  ConsumerState<_LessonEditorSheet> createState() => _LessonEditorSheetState();
}

class _LessonEditorSheetState extends ConsumerState<_LessonEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _topicController;
  late final TextEditingController _difficultyController;
  late final TextEditingController _minutesController;
  late final TextEditingController _objectivesController;
  late final TextEditingController _contentController;
  late final TextEditingController _vocabController;
  late final TextEditingController _competencyController;
  late final TextEditingController _resourceController;
  late final TextEditingController _bannerController;
  bool _isPublished = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isUploadingResource = false;
  Uint8List? _localPreviewImageBytes;
  XFile? _pendingImageFile;
  PlatformFile? _pendingSupplementFile;
  String _supplementFileUrl = '';
  String _supplementFileName = '';
  String _supplementFileType = '';

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _topicController = TextEditingController(text: existing?.topic ?? '');
    _difficultyController = TextEditingController(
      text: existing?.difficulty ?? 'Beginner',
    );
    _minutesController = TextEditingController(
      text: '${existing?.estimatedMinutes ?? 40}',
    );
    _objectivesController = TextEditingController(
      text: existing?.objectives.join('\n') ?? '',
    );
    _contentController = TextEditingController(text: existing?.content ?? '');
    _vocabController = TextEditingController(
      text: existing?.vocabularyTerms.join(', ') ?? '',
    );
    _competencyController = TextEditingController(
      text: existing?.competencyTag ?? 'Concept Mastery',
    );
    _resourceController = TextEditingController(
      text: existing?.resourceLinks.join('\n') ?? '',
    );
    _bannerController = TextEditingController(
      text: normalizeLessonImagePath(existing?.bannerUrl),
    );
    _isPublished = existing?.isPublished ?? true;
    _supplementFileUrl = existing?.supplementFileUrl ?? '';
    _supplementFileName = existing?.supplementFileName ?? '';
    _supplementFileType = existing?.supplementFileType ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _difficultyController.dispose();
    _minutesController.dispose();
    _objectivesController.dispose();
    _contentController.dispose();
    _vocabController.dispose();
    _competencyController.dispose();
    _resourceController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  String _resolvedBannerPath() {
    return normalizeLessonImagePath(_bannerController.text);
  }

  bool _isDataImageUri(String value) {
    return value.startsWith('data:image/');
  }

  Uint8List? _decodeDataImageUri(String value) {
    if (!_isDataImageUri(value)) {
      return null;
    }
    final commaIndex = value.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= value.length - 1) {
      return null;
    }
    final encoded = value.substring(commaIndex + 1);
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  Widget _buildImagePreview() {
    final localBytes = _localPreviewImageBytes;
    final bannerPath = _resolvedBannerPath();

    if (localBytes != null) {
      return Image.memory(
        localBytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePreviewFallback(),
      );
    }

    if (bannerPath.isEmpty) {
      return _imagePreviewFallback(label: 'No image selected yet');
    }

    if (bannerPath.startsWith('http://') || bannerPath.startsWith('https://')) {
      return Image.network(
        bannerPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePreviewFallback(),
      );
    }

    final dataBytes = _decodeDataImageUri(bannerPath);
    if (dataBytes != null) {
      return Image.memory(
        dataBytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePreviewFallback(),
      );
    }

    return Image.asset(
      bannerPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagePreviewFallback(),
    );
  }

  Widget _imagePreviewFallback({String label = 'Image preview unavailable'}) {
    return Container(
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: Text(label),
    );
  }

  String _selectedImageLabel() {
    final pending = _pendingImageFile;
    if (pending != null && pending.path.isNotEmpty) {
      return pending.path.split(RegExp(r'[\\/]')).last;
    }
    if (_isDataImageUri(_resolvedBannerPath())) {
      return 'Inline uploaded image';
    }
    return lessonImageLabel(_resolvedBannerPath());
  }

  Future<void> _pickImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    setState(() {
      _pendingImageFile = file;
      _localPreviewImageBytes = bytes;
    });
  }

  String _selectedSupplementLabel() {
    final pending = _pendingSupplementFile;
    if (pending != null && pending.name.trim().isNotEmpty) {
      return pending.name.trim();
    }
    if (_supplementFileName.trim().isNotEmpty) {
      return _supplementFileName.trim();
    }
    return 'No file selected';
  }

  Future<void> _pickSupplementFile() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'ppt', 'pptx'],
      allowMultiple: false,
      withData: true,
    );
    final files = result?.files ?? const <PlatformFile>[];
    final file = files.isEmpty ? null : files.first;
    if (file == null) {
      return;
    }

    final ext = (file.extension ?? '').toLowerCase();
    if (ext != 'pdf' && ext != 'ppt' && ext != 'pptx') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only PDF, PPT, and PPTX are supported.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _pendingSupplementFile = file;
      _supplementFileName = file.name;
      _supplementFileType = ext;
    });
  }

  Future<String?> _uploadPendingImageIfNeeded() async {
    const maxInlineImageBytes = 800 * 1024;
    final file = _pendingImageFile;
    if (file == null) {
      return _resolvedBannerPath();
    }
    final bytes = _localPreviewImageBytes ?? await file.readAsBytes();
    final ext = file.path.contains('.')
        ? file.path.split('.').last.toLowerCase()
        : 'jpg';
    final safeExt = (ext == 'png' || ext == 'webp' || ext == 'jpeg')
        ? ext
        : 'jpeg';
    final storageExt = safeExt == 'jpeg' ? 'jpg' : safeExt;
    final mimeType = safeExt == 'jpeg' ? 'image/jpeg' : 'image/$safeExt';

    try {
      final ref = FirebaseStorage.instance.ref().child(
        'lesson_banners/${DateTime.now().millisecondsSinceEpoch}.$storageExt',
      );
      await ref.putData(bytes, SettableMetadata(contentType: mimeType));
      return await ref.getDownloadURL();
    } catch (_) {
      if (bytes.lengthInBytes > maxInlineImageBytes) {
        return null;
      }
      final encoded = base64Encode(bytes);
      return 'data:$mimeType;base64,$encoded';
    }
  }

  Future<_SupplementUploadResult?> _uploadSupplementIfNeeded() async {
    final pending = _pendingSupplementFile;
    if (pending == null) {
      return _SupplementUploadResult(
        url: _supplementFileUrl,
        name: _supplementFileName,
        type: _supplementFileType,
      );
    }

    final ext = (pending.extension ?? '').toLowerCase();
    if (ext != 'pdf' && ext != 'ppt' && ext != 'pptx') {
      return null;
    }

    final bytes = pending.bytes;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final contentType = switch (ext) {
      'pdf' => 'application/pdf',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      _ => 'application/octet-stream',
    };

    try {
      final ref = FirebaseStorage.instance.ref().child(
        'lesson_resources/${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      final url = await ref.getDownloadURL();
      return _SupplementUploadResult(url: url, name: pending.name, type: ext);
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _titleController.text.trim();
    final topic = _topicController.text.trim();
    final difficulty = _difficultyController.text.trim();
    final content = _contentController.text.trim();
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 40;
    final bannerPath = _resolvedBannerPath();

    if (_isUploadingImage || _isUploadingResource) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload is still in progress. Please wait a moment.'),
        ),
      );
      return;
    }

    if (title.isEmpty ||
        topic.isEmpty ||
        difficulty.isEmpty ||
        content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    if (bannerPath.isEmpty && _pendingImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select one lesson image before uploading.'),
        ),
      );
      return;
    }

    final objectives = _objectivesController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (objectives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one learning objective.')),
      );
      return;
    }

    setState(() => _isUploadingImage = true);
    final uploadedImageUrl = await _uploadPendingImageIfNeeded();
    setState(() => _isUploadingImage = false);
    if (uploadedImageUrl == null || uploadedImageUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Image upload failed. Try a smaller image or better network, then upload again.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isUploadingResource = true);
    final supplement = await _uploadSupplementIfNeeded();
    setState(() => _isUploadingResource = false);
    if (supplement == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'File upload failed. Only PDF/PPT/PPTX files are supported.',
            ),
          ),
        );
      }
      return;
    }

    _supplementFileUrl = supplement.url;
    _supplementFileName = supplement.name;
    _supplementFileType = supplement.type;

    _bannerController.text = uploadedImageUrl;
    final teacherId = ref.read(currentUserProvider).valueOrNull?.uid;
    final existing = widget.existing;
    final lessonId =
        existing?.lessonId ??
        '${title.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

    final lesson = Lesson(
      lessonId: lessonId,
      title: title,
      topic: topic,
      difficulty: difficulty,
      objectives: objectives,
      content: content,
      vocabularyTerms: _vocabController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      competencyTag: _competencyController.text.trim(),
      bannerUrl: uploadedImageUrl,
      estimatedMinutes: minutes.clamp(5, 180),
      resourceLinks: _resourceController.text
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      isPublished: _isPublished,
      createdBy: teacherId ?? existing?.createdBy ?? 'teacher_local',
      createdAt: existing?.createdAt ?? DateTime.now(),
      supplementFileUrl: _supplementFileUrl,
      supplementFileName: _supplementFileName,
      supplementFileType: _supplementFileType,
    );

    setState(() => _isSaving = true);
    await ref.read(lessonRepositoryProvider).upsertLesson(lesson);
    if (_isPublished) {
      await ref
          .read(notificationRepositoryProvider)
          .createRoleNotification(
            role: 'student',
            title: existing == null ? 'New Lesson Published' : 'Lesson Updated',
            message:
                '$title is now available in your lessons. Open the app to start learning.',
            createdBy: teacherId ?? 'teacher_local',
          );
    }
    ref.invalidate(lessonsProvider);
    ref.invalidate(lessonsStreamProvider);
    ref.invalidate(studentLessonsProvider);
    ref.invalidate(studentLessonsStreamProvider);
    ref.invalidate(notificationsProvider);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F8FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 64,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Lesson' : 'Upload New Lesson',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Add your lesson content and publish it for students.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(
                      controller: _titleController,
                      label: 'Title *',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _topicController,
                            label: 'Topic *',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: CustomTextField(
                            controller: _difficultyController,
                            label: 'Difficulty *',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _minutesController,
                            label: 'Minutes',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: CustomTextField(
                            controller: _competencyController,
                            label: 'Competency Tag',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CustomTextField(
                      controller: _objectivesController,
                      label: 'Objectives (one per line) *',
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CustomTextField(
                      controller: _contentController,
                      label: 'Lesson Content *',
                      maxLines: 7,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CustomTextField(
                      controller: _vocabController,
                      label: 'Vocabulary (comma separated)',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CustomTextField(
                      controller: _resourceController,
                      label: 'Resource Links (one per line)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Selected Image: ${_selectedImageLabel()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isUploadingImage ? null : _pickImage,
                          icon: _isUploadingImage
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _isUploadingImage ? 'Uploading...' : 'Select Image',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 132,
                        width: double.infinity,
                        child: _buildImagePreview(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Lesson File (PDF/PPT/PPTX)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selected: ${_selectedSupplementLabel()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        OutlinedButton.icon(
                          onPressed: (_isUploadingImage || _isUploadingResource)
                              ? null
                              : _pickSupplementFile,
                          icon: _isUploadingResource
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.attach_file_rounded),
                          label: Text(
                            _isUploadingResource
                                ? 'Uploading file...'
                                : 'Select PDF/PPT',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _isPublished,
                      activeColor: AppColors.secondary,
                      title: const Text('Publish for students'),
                      subtitle: const Text(
                        'Turn off to keep this as draft only.',
                      ),
                      onChanged: (value) =>
                          setState(() => _isPublished = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: TapScale(
                        onTap:
                            (_isSaving ||
                                _isUploadingImage ||
                                _isUploadingResource)
                            ? null
                            : _save,
                        child: FilledButton.icon(
                          onPressed:
                              (_isSaving ||
                                  _isUploadingImage ||
                                  _isUploadingResource)
                              ? null
                              : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isEdit
                                      ? Icons.check_circle_rounded
                                      : Icons.upload_rounded,
                                ),
                          label: Text(
                            _isSaving
                                ? 'Saving...'
                                : (_isUploadingImage
                                      ? 'Uploading image...'
                                      : (_isUploadingResource
                                            ? 'Uploading file...'
                                            : (isEdit
                                                  ? 'Update Lesson'
                                                  : 'Upload Lesson'))),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplementUploadResult {
  const _SupplementUploadResult({
    required this.url,
    required this.name,
    required this.type,
  });

  final String url;
  final String name;
  final String type;
}

class _LessonListLeading extends StatelessWidget {
  const _LessonListLeading({
    required this.lessonId,
    required this.imageUrl,
    required this.isPublished,
  });

  final String lessonId;
  final String imageUrl;
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final iconColor = isPublished
        ? AppColors.secondary
        : const Color(0xFFE78A00);
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: LessonTopicArtwork(
              lessonId: lessonId,
              imageUrl: imageUrl,
              height: 58,
              width: 58,
              borderRadius: 14,
              showLabel: false,
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                isPublished ? Icons.public_rounded : Icons.edit_rounded,
                size: 12,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
