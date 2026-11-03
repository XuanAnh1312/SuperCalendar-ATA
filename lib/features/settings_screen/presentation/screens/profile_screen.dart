import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter_application/app/routes/app_routes.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_text.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/core/widgets/app_widgets.dart';
import 'package:flutter_application/features/settings_screen/domain/user.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/widget_style_screen.dart';

/// Round avatar: the user's photo when the file still exists, else initials.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.user,
    this.avatarPath,
    this.radius = 20,
    this.background,
  });

  final User user;

  /// Overrides [User.avatar] while a new photo is not saved yet.
  final String? avatarPath;
  final double radius;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final path = avatarPath ?? user.avatar;
    final file = path == null ? null : File(path);
    final hasPhoto = file != null && file.existsSync();
    return CircleAvatar(
      radius: radius,
      backgroundColor: background ?? AppColors.pink,
      backgroundImage: hasPhoto ? FileImage(file) : null,
      child: hasPhoto
          ? null
          : Text(
              user.initials,
              style: AppText.s(radius * 0.6, color: AppColors.primary),
            ),
    );
  }
}

/// "Profile & account" (Settings 27, FR-02): photo, name, email and the
/// membership. Changes are kept here until "Save profile".
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _name;
  late String _email;
  String? _avatar;

  @override
  void initState() {
    super.initState();
    final user = AppScope.read(context).user;
    _name = user.name;
    _email = user.email ?? '';
  }

  Future<void> _changePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) setState(() => _avatar = picked.path);
  }

  Future<void> _editName() async {
    final name = await promptText(
      context,
      title: 'Your name',
      initial: _name,
      hint: 'Name',
    );
    if (name != null && name.trim().isNotEmpty && mounted) {
      setState(() => _name = name.trim());
    }
  }

  Future<void> _editEmail() async {
    final email = await promptText(
      context,
      title: 'Email',
      initial: _email,
      hint: 'name@example.com',
    );
    if (email != null && mounted) setState(() => _email = email.trim());
  }

  void _save() {
    final account = AppScope.read(context).account;
    account.rename(_name);
    account.updateProfile(email: _email, avatar: _avatar);
    showAppSnack(context, 'Profile saved');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            StudioHeader(
              title: 'Profile & account',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Center(
                    child: ProfileAvatar(
                      user: app.user,
                      avatarPath: _avatar,
                      radius: 40,
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _changePhoto,
                      child: Text(
                        tr('Change photo'),
                        style: AppText.s(
                          13,
                          weight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        tr(app.isVip ? 'VIP member' : 'Free plan'),
                        style: AppText.s(11.5, color: AppColors.muted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ProfileField(
                    label: 'Name',
                    value: _name,
                    highlighted: true,
                    onTap: _editName,
                  ),
                  const SizedBox(height: 12),
                  _ProfileField(
                    icon: LucideIcons.mail,
                    label: 'Email',
                    value: _email.isEmpty ? tr('Add your email') : _email,
                    onTap: _editEmail,
                  ),
                  const SizedBox(height: 12),
                  // Prototype mock: there is no cloud sync (README §10); the
                  // design's device card is shown as-is.
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    shadow: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr('Connected devices'),
                                style: AppText.s(15, weight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              tr('3 devices'),
                              style: AppText.s(
                                12,
                                weight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                            'Your calendar, tasks and notes are synced across '
                            'your connected devices.',
                          ),
                          style: AppText.s(
                            12.5,
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (final icon in [
                              LucideIcons.smartphone,
                              LucideIcons.tablet,
                              LucideIcons.laptop,
                            ]) ...[
                              Icon(icon, size: 22, color: AppColors.primary),
                              const SizedBox(width: 18),
                            ],
                            Icon(
                              LucideIcons.check,
                              size: 13,
                              color: AppColors.greenStrong,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tr('Up to date'),
                              style: AppText.s(
                                12,
                                color: AppColors.greenStrong,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    color: AppColors.primarySoft,
                    borderColor: Colors.transparent,
                    shadow: false,
                    padding: const EdgeInsets.all(16),
                    onTap: () => goToTab(context, AppTab.vip),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr('VIP membership'),
                                style: AppText.s(15, weight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              tr(app.isVip ? 'Manage plan' : 'Upgrade'),
                              style: AppText.s(
                                12,
                                weight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                            app.isVip
                                ? 'Premium templates and personal styles are '
                                      'available on your account.'
                                : 'Upgrade to unlock the Theme Builder',
                          ),
                          style: AppText.s(
                            12.5,
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            StudioActions(
              children: [StudioButton(label: 'Save profile', onTap: _save)],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordered field with a small label, the value and a chevron.
class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      shadow: false,
      borderColor: highlighted ? AppColors.primary : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(label), style: AppText.s(11, color: AppColors.muted)),
                const SizedBox(height: 3),
                Text(value, style: AppText.s(14)),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 16, color: AppColors.muted),
        ],
      ),
    );
  }
}
