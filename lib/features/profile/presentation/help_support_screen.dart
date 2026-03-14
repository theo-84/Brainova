import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Frequently Asked Questions'),
            const SizedBox(height: 16),
            const _FAQToggleItem(
              question: 'What is the Brain Rot Meter?',
              answer:
                  'The Brain Rot Meter measures your digital consumption habits over the last 24 hours. A higher score means more time spent on non-productive screen activities. The score is based on your activity during the last 24 hours and updates automatically throughout the day.',
            ),
            const _FAQToggleItem(
              question: 'How is my score calculated?',
              answer:
                  'Your score is based on how long you use certain apps. Entertainment and social media apps increase your score, while learning and productivity apps lower it. Mind Resets and Rewire sessions also reduce your score.',
            ),
            const _FAQToggleItem(
              question: 'What is a Mind Reset?',
              answer:
                  'A Mind Reset is a short activity that helps counteract brain rot. Completing one reduces your Brain Rot Score significantly.',
            ),
            const _FAQToggleItem(
              question: 'What is Rewire Mode?',
              answer:
                  'Rewire Mode gives you productive tasks to replace passive screen time. Completing rewire tasks earns points and reduces your Brain Rot Score.',
            ),
            const _FAQToggleItem(
              question: 'Why does the app need Usage Access permission?',
              answer:
                  'Usage Access permission allows Brainova to detect which apps you are using and for how long. Without this permission, the app cannot track your digital habits automatically.',
            ),
            const _FAQToggleItem(
              question: 'How do I improve my score?',
              answer:
                  'Use learning apps, complete Mind Resets, do Rewire tasks, reduce social media and entertainment consumption, and maintain a daily streak.',
            ),
            const _FAQToggleItem(
              question: 'Is my data private?',
              answer:
                  'Yes. Your data is stored securely and only accessible to you. We never share your personal usage data with third parties.',
            ),
            const _FAQToggleItem(
              question: 'How do I delete my data?',
              answer:
                  'You can delete your account from the Profile screen. This will permanently remove your access and associated activity data.',
            ),
            const _FAQToggleItem(
              question:
                  'What is the difference between Brain Rot Meter and Reality Check?',
              answer:
                  'The Brain Rot Meter shows your overall stimulation score based on your activity over the last 24 hours. Reality Check analyzes the balance of your digital habits and provides insights into whether your current usage is healthy or overstimulating.',
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Troubleshooting'),
            const SizedBox(height: 16),
            const _FAQStaticItem(
              question: 'Why is my score not updating?',
              answer:
                  'Make sure Usage Access permission is enabled for Brainova so the app can detect which apps you are using. Also ensure the app is not restricted by battery optimization settings. It may take a short time for new activity data to be logged and reflected in your score.',
              icon: LucideIcons.alertCircle,
              color: AppTheme.warning,
            ),
            const _FAQStaticItem(
              question: 'Can I reset my Brain Rot Score manually?',
              answer:
                  'The Brain Rot Score is calculated from your activity over the last 24 hours, so it gradually decreases as older activity expires. Completing Mind Reset activities or Rewire tasks can also help reduce your score during the day.',
              icon: LucideIcons.helpCircle,
              color: AppTheme.primary,
            ),
            const _FAQStaticItem(
              question: 'Why am I receiving notifications?',
              answer:
                  'Brainova sends notifications to help you stay aware of your digital habits. You may receive alerts when your Brain Rot Score becomes high or reminders to complete a Mind Reset or Rewire activity.',
              icon: LucideIcons.bell,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }
}

class _FAQToggleItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQToggleItem({required this.question, required this.answer});

  @override
  State<_FAQToggleItem> createState() => _FAQToggleItemState();
}

class _FAQToggleItemState extends State<_FAQToggleItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          onExpansionChanged: (val) => setState(() => _expanded = val),
          trailing: Icon(
            _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            color: AppTheme.primary,
            size: 18,
          ),
          title: Text(
            widget.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQStaticItem extends StatelessWidget {
  final String question;
  final String answer;
  final IconData icon;
  final Color color;

  const _FAQStaticItem({
    required this.question,
    required this.answer,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
