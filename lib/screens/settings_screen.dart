import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/caption_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/ui_helpers.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'smitboraniya08@gmail.com',
      queryParameters: {
        'subject': 'AI Caption Studio Support',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No email app found. Please email smitboraniya08@gmail.com"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final url = Uri.parse("https://play.google.com/store/apps/details?id=${packageInfo.packageName}");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _shareApp() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final url = "https://play.google.com/store/apps/details?id=${packageInfo.packageName}";
    Share.share("Check out AI Caption Studio on the Play Store:\n$url");
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
          children: [
            // Profile/About Header
            ModernCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Caption Studio", style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final version = snapshot.data?.version ?? "1.0.0";
                          return Text("Version $version", style: theme.textTheme.bodySmall);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const SectionHeader(title: "Preferences"),
            ModernCard(
              padding: EdgeInsets.zero,
              child: _SettingsTile(
                icon: Icons.dark_mode_rounded,
                title: "Dark Mode",
                subtitle: "Easier on your eyes",
                trailing: Switch(
                  value: settings.darkMode,
                  onChanged: (val) => settings.setDarkMode(val),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            const SectionHeader(title: "Support"),
            ModernCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: "Privacy Policy",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    ),
                  ),
                  const _Divider(),
                  _SettingsTile(
                    icon: Icons.star_outline_rounded,
                    title: "Rate App",
                    onTap: _rateApp,
                  ),
                  const _Divider(),
                  _SettingsTile(
                    icon: Icons.share_outlined,
                    title: "Tell a Friend",
                    onTap: _shareApp,
                  ),
                  const _Divider(),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: "Help & Support",
                    onTap: () => _sendEmail(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey.withOpacity(0.1));
  }
}
