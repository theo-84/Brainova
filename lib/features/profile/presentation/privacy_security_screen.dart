import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/service/notification_service.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PrivacyToggleItem(
              icon: LucideIcons.database,
              title: 'Data Collection',
              content:
                  'Brainova collects your app usage data on your device to calculate your Brain Rot meter and Reality Check insights. This data is stored securely in your personal account and is never shared with third parties.',
            ),
            const _PrivacyToggleItem(
              icon: LucideIcons.eye,
              title: 'What We Track',
              content:
                  'We track which apps you use and for how long. This includes entertainment apps, social media, and productivity tools. We do not access the content of your apps or messages.',
            ),
            const _PrivacyToggleItem(
              icon: LucideIcons.shieldCheck,
              title: 'Data Security',
              content:
                  'Your data is securely stored using Firebase. Access to your activity data is protected through authentication and encrypted connections to keep your information safe.',
            ),
            const _PrivacyToggleItem(
              icon: LucideIcons.userX,
              title: 'Your Rights',
              content:
                  'You have the right to delete your data at any time. You can also revoke app usage permissions from your device settings at any time. Deleting your account will permanently remove all your stored data.',
            ),
            const SizedBox(height: 24),
            Text(
              'Reliability Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Background Alerts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To receive alerts even when you are not using the app, please ensure "Unrestricted" battery usage is enabled for Brainova.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => NotificationService()
                          .requestBatteryOptimizationExemption(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: AppTheme.primary.withOpacity(0.2)),
                        ),
                      ),
                      child: const Text('Enable Reliable Alerts'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Permissions Used',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const _PrivacyStaticItem(
              icon: LucideIcons.activity,
              title: 'Usage Access',
              description: 'Usage Access — to track which apps you use.',
            ),
            const _PrivacyStaticItem(
              icon: LucideIcons.bell,
              title: 'Notifications',
              description:
                  'Notifications — to alert you when Brain Rot scores are high.',
            ),
            const _PrivacyStaticItem(
              icon: LucideIcons.globe,
              title: 'Internet',
              description: 'Internet — to sync your data securely.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PrivacyToggleItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String content;

  const _PrivacyToggleItem({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  State<_PrivacyToggleItem> createState() => _PrivacyToggleItemState();
}

class _PrivacyToggleItemState extends State<_PrivacyToggleItem> {
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
          leading: Icon(
            widget.icon,
            color: AppTheme.primary,
            size: 20,
          ),
          trailing: Icon(
            _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            color: AppTheme.primary,
            size: 18,
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.content,
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

class _PrivacyStaticItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PrivacyStaticItem({
    required this.icon,
    required this.title,
    required this.description,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
