import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/caption_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/caption_request.dart';
import '../models/favorite_entry.dart';
import '../utils/ui_helpers.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  BannerAd? banner;

  @override
  void initState() {
    super.initState();
    final ads = context.read<CaptionProvider>().ads;
    banner = ads.createBanner()..load();
  }

  @override
  void dispose() {
    banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaptionProvider>();
    final theme = Theme.of(context);

    // Search all history for the first entry with real content,
    // since history.first is the just-saved entry which may be blank if backend failed.
    final String resolvedDescription = vm.imageDescription?.isNotEmpty == true
        ? vm.imageDescription!
        : vm.history
            .map((e) => e.description)
            .firstWhere((d) => d.trim().isNotEmpty, orElse: () => '');

    final List<String> resolvedTags = vm.tags.isNotEmpty
        ? vm.tags
        : vm.history
            .map((e) => e.tags)
            .firstWhere((t) => t.isNotEmpty, orElse: () => []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Results"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            children: [
              // 1. AI Analysis Section (Always Visible)
              const SectionHeader(title: "AI Analysis"),
              ModernCard(
                child: Text(
                  resolvedDescription.isNotEmpty
                      ? resolvedDescription
                      : 'AI analysis is unavailable for this image.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    fontStyle: resolvedDescription.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 2. Captions Section (Horizontal)
              const SectionHeader(title: "Generated Captions"),
              if (vm.captions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text("No captions found.", style: theme.textTheme.bodyMedium),
                  ),
                )
              else
                SizedBox(
                  height: 440,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.9),
                    itemCount: vm.captions.length,
                    itemBuilder: (context, index) {
                      final caption = vm.captions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _ModernCaptionCard(
                          caption: caption,
                          index: index,
                          imageBase64: vm.history.isNotEmpty ? vm.history.first.imageBase64 : null,
                        ),
                      );
                    },
                  ),
                ),

              // 3. Hashtags Section (Always Visible)
              const SizedBox(height: 32),
              const SectionHeader(title: "Hashtags"),
              ModernCard(
                child: resolvedTags.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: resolvedTags
                            .map((tag) => _HashtagChip(tag: tag))
                            .toList(),
                      )
                    : Text(
                        'No hashtags available.',
                        style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                      ),
              ),
            ],
          ),
          
          if (banner != null)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                child: SizedBox(
                  height: banner!.size.height.toDouble(),
                  width: banner!.size.width.toDouble(),
                  child: AdWidget(ad: banner!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModernCaptionCard extends StatelessWidget {
  final String caption;
  final int index;
  final String? imageBase64;

  const _ModernCaptionCard({
    required this.caption,
    required this.index,
    this.imageBase64,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favVm = context.watch<FavoritesProvider>();
    final id = caption.hashCode.toRadixString(16);
    final isFav = favVm.isFavorite(id);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0), // Horizontal slide
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: ModernCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Action Buttons below the card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionCircleButton(
                icon: Icons.auto_fix_high_rounded,
                label: "Transform",
                onTap: () => _showTransformSheet(context, caption),
              ),
              _ActionCircleButton(
                icon: Icons.share_rounded,
                label: "Share",
                onTap: () => _showSharePicker(context, caption),
              ),
              _ActionCircleButton(
                icon: Icons.copy_rounded,
                label: "Copy",
                onTap: () {
                  Clipboard.setData(ClipboardData(text: caption));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Copied!"), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
              _ActionCircleButton(
                icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: "Save",
                color: isFav ? Colors.redAccent : null,
                onTap: () async {
                  if (isFav) {
                    await favVm.removeFavorite(id);
                  } else {
                    await favVm.addFavorite(
                      FavoriteEntry(
                        id: id,
                        caption: caption,
                        imageBase64: imageBase64,
                        savedAt: DateTime.now(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showTransformSheet(BuildContext context, String caption) {
    final vm = context.read<CaptionProvider>();
    final variants = vm.transformCaption(caption);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransformSheet(caption: caption, variants: variants),
    );
  }

  void _showSharePicker(BuildContext context, String text) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareSheet(text: text),
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionCircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color?.withOpacity(0.1) ?? theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final String tag;
  const _HashtagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final String text;
  const _ShareSheet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text("Share Caption", style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          _ShareOption(
            icon: Icons.copy_rounded,
            label: "Copy Text",
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
            },
          ),
          _ShareOption(
            icon: Icons.chat_bubble_outline_rounded,
            label: "WhatsApp",
            onTap: () async {
              final url = "https://wa.me/?text=${Uri.encodeComponent(text)}";
              if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _TransformSheet extends StatelessWidget {
  final String caption;
  final List<String> variants;

  const _TransformSheet({required this.caption, required this.variants});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text("Transform Styles", style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ModernCard(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              child: Text(caption, style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: variants.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ModernCard(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: variants[index]));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                    },
                    child: Text(variants[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
