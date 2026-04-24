import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/models/evaluation_feedback.dart';
import '../../providers/evaluation_providers.dart';

class EvaluationFormScreen extends ConsumerStatefulWidget {
  const EvaluationFormScreen({super.key});

  @override
  ConsumerState<EvaluationFormScreen> createState() =>
      _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends ConsumerState<EvaluationFormScreen> {
  final TextEditingController _commentsController = TextEditingController();
  String _testType = 'alpha';
  int _engagement = 4;
  int _functionality = 4;
  int _aesthetics = 4;
  int _information = 4;
  int _impact = 4;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = await ref.read(currentUserProvider.future);
    final feedback = EvaluationFeedback(
      feedbackId: 'feedback_${DateTime.now().millisecondsSinceEpoch}',
      userId: user?.uid ?? 'local_user',
      role: user?.role.name ?? 'student',
      engagement: _engagement,
      functionality: _functionality,
      aesthetics: _aesthetics,
      information: _information,
      perceivedImpact: _impact,
      comments: _commentsController.text.trim(),
      testType: _testType,
      createdAt: DateTime.now(),
    );

    await ref.read(evaluationControllerProvider.notifier).submit(feedback);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evaluation submitted. Thank you!')),
    );
    _commentsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evaluationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Research Evaluation Form')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Alpha/Beta Testing Feedback',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Provide ratings for engagement, functionality, aesthetics, information quality, and perceived learning impact.',
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              value: _testType,
              decoration: const InputDecoration(labelText: 'Test Type'),
              items: const [
                DropdownMenuItem(value: 'alpha', child: Text('Alpha Testing')),
                DropdownMenuItem(value: 'beta', child: Text('Beta Testing')),
              ],
              onChanged: (value) =>
                  setState(() => _testType = value ?? 'alpha'),
            ),
            const SizedBox(height: AppSpacing.md),
            _RatingSlider(
              label: 'Engagement',
              value: _engagement,
              onChanged: (value) => setState(() => _engagement = value),
            ),
            _RatingSlider(
              label: 'Functionality',
              value: _functionality,
              onChanged: (value) => setState(() => _functionality = value),
            ),
            _RatingSlider(
              label: 'Aesthetics',
              value: _aesthetics,
              onChanged: (value) => setState(() => _aesthetics = value),
            ),
            _RatingSlider(
              label: 'Information',
              value: _information,
              onChanged: (value) => setState(() => _information = value),
            ),
            _RatingSlider(
              label: 'Perceived Impact',
              value: _impact,
              onChanged: (value) => setState(() => _impact = value),
            ),
            const SizedBox(height: AppSpacing.md),
            CustomTextField(
              controller: _commentsController,
              label: 'Comments',
              maxLines: 5,
              hint: 'Share strengths, gaps, and suggested improvements.',
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              label: 'Submit Evaluation',
              isLoading: state.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label)),
                Text('$value/5'),
              ],
            ),
            Slider(
              value: value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$value',
              onChanged: (v) => onChanged(v.round()),
            ),
          ],
        ),
      ),
    );
  }
}
