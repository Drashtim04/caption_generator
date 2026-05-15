import 'package:flutter/material.dart';
import '../utils/ui_helpers.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  theme,
                  "1. Data Collection",
                  "AI Caption Studio collects minimal data to provide its services. Images you upload are processed by AI models to generate captions and are not stored permanently on our servers beyond the processing window.",
                ),
                _buildSection(
                  theme,
                  "2. Local Storage",
                  "Your generation history and favorite captions are stored locally on your device using encrypted and secure storage methods. We do not have access to this data.",
                ),
                _buildSection(
                  theme,
                  "3. AI Processing",
                  "We use third-party AI providers (like Google Gemini) to process images. By using this app, you agree to their respective privacy policies regarding data processing.",
                ),
                _buildSection(
                  theme,
                  "4. Advertising",
                  "We use AdMob to display ads. AdMob may collect and use data for ad personalization according to their privacy policy.",
                ),
                _buildSection(
                  theme,
                  "5. Your Rights",
                  "You can clear your local history and favorites at any time through the app settings or by deleting the app's local data in your device settings.",
                ),
                const SizedBox(height: 20),
                Text(
                  "Last Updated: May 2026",
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
