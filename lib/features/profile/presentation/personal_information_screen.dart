import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_providers.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedCountry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).currentUser;
    _nameController = TextEditingController(text: user?.displayName);
    _phoneController = TextEditingController(text: user?.phoneNumber);
    _selectedDate = user?.dateOfBirth;
    _selectedGender = user?.gender;
    _selectedCountry = user?.country;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            displayName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            dateOfBirth: _selectedDate,
            gender: _selectedGender,
            country: _selectedCountry,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        actions: [
          if (_isLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.surfaceHighlight,
                  child: Text(
                    (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField('Full Name', _nameController, LucideIcons.user,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 20),

              _buildReadOnlyField(
                  'Email Address', user?.email ?? '', LucideIcons.mail,
                  trailing: Text(
                      user != null &&
                              FirebaseAuth
                                      .instance.currentUser?.emailVerified ==
                                  true
                          ? 'Verified'
                          : 'Not Verified',
                      style: TextStyle(
                          color: user != null &&
                                  FirebaseAuth.instance.currentUser
                                          ?.emailVerified ==
                                      true
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 12))),
              const SizedBox(height: 20),

              _buildTextField(
                  'Phone Number', _phoneController, LucideIcons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 20),

              // Date of Birth
              _buildPickerField(
                  'Date of Birth',
                  _selectedDate == null
                      ? 'Select Date'
                      : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                  LucideIcons.calendar, () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ??
                      DateTime.now().subtract(const Duration(days: 365 * 20)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              }),
              const SizedBox(height: 20),

              _buildDropdownField(
                  'Gender',
                  _selectedGender,
                  LucideIcons.users,
                  ['Male', 'Female', 'Prefer not to say'],
                  (v) => setState(() => _selectedGender = v)),
              const SizedBox(height: 20),

              _buildDropdownField(
                  'Country / Region',
                  _selectedCountry,
                  LucideIcons.globe,
                  [
                    'USA',
                    'UK',
                    'Egypt',
                    'UAE',
                    'Saudi Arabia',
                    'Kuwait',
                    'Jordan'
                  ],
                  (v) => setState(() => _selectedCountry = v)),
              const SizedBox(height: 32),

              _buildActionTile('Change Password', LucideIcons.lock,
                  () => _showChangePasswordDialog()),
              const SizedBox(height: 16),
              _buildActionTile('Delete Account', LucideIcons.trash2,
                  () => _showDeleteAccountDialog(),
                  color: AppTheme.error),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon,
      {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
              color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: Colors.grey, size: 20),
            title: Text(value, style: const TextStyle(color: Colors.white70)),
            trailing: trailing,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField(
      String label, String value, IconData icon, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey, size: 20),
                const SizedBox(width: 16),
                Text(value, style: const TextStyle(color: Colors.white)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? value, IconData icon,
      List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.surface,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              hint:
                  const Text('Select', style: TextStyle(color: Colors.white54)),
              items: items
                  .map((String item) => DropdownMenuItem(
                      value: item,
                      child: Text(item,
                          style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap,
      {Color color = Colors.white}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 20),
      title: Text(title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      trailing:
          Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 16),
      tileColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Change Password',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: currentController,
                decoration:
                    const InputDecoration(labelText: 'Current Password'),
                obscureText: true),
            TextField(
                controller: newController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => context.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(authRepositoryProvider)
                    .updatePassword(currentController.text, newController.text);
                if (context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final isGoogle = FirebaseAuth.instance.currentUser?.providerData
            .any((p) => p.providerId == 'google.com') ??
        false;
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Account',
            style: TextStyle(color: AppTheme.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'This action is irreversible. All your data will be permanently deleted.',
                style: TextStyle(color: Colors.white70)),
            if (!isGoogle) ...[
              const SizedBox(height: 16),
              TextField(
                  controller: passwordController,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => context.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                setState(() => _isLoading = true);
                context.pop();
                await ref.read(authRepositoryProvider).deleteAccount(
                    password: isGoogle ? null : passwordController.text);
                if (mounted) context.go('/login');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: Text(isGoogle ? 'Confirm with Google' : 'Delete',
                style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
