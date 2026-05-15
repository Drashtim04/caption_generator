import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/caption_request.dart';
import '../providers/caption_provider.dart';
import '../utils/app_constants.dart';
import '../utils/ui_helpers.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final picker = ImagePicker();
  final _keywordsController = TextEditingController();
  Uint8List? imageBytes;
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
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => imageBytes = bytes);
    context.read<CaptionProvider>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaptionProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Decor
          Positioned(
            top: -100,
            right: -100,
            child: _GlowCircle(color: theme.colorScheme.primary.withOpacity(0.1), size: 300),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _GlowCircle(color: theme.colorScheme.secondary.withOpacity(0.05), size: 200),
          ),
          
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Caption Studio",
                                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                                ),
                                Text(
                                  "AI-powered creativity.",
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            _DailyLimitBadge(vm: vm),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Image Section
                        SectionHeader(
                          title: "Upload Photo",
                          trailing: imageBytes != null 
                            ? TextButton(onPressed: pickImage, child: const Text("Change"))
                            : null,
                        ),
                        _ImagePickerContainer(
                          imageBytes: imageBytes,
                          onTap: pickImage,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Controls Section
                        const SectionHeader(title: "Style & Tone"),
                        ModernCard(
                          padding: const EdgeInsets.all(20),
                          child: _CaptionEngineControls(
                            keywordsController: _keywordsController,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        PremiumButton(
                          label: vm.loading ? "Creating Magic..." : "Generate Captions",
                          icon: Icons.auto_awesome_rounded,
                          loading: vm.loading,
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            final nav = Navigator.of(context);
                            vm.setKeywords(_keywordsController.text);
                            await vm.generateFromImageBytes(imageBytes);
                            if (!mounted) return;
                            if (vm.error == null && (vm.imageDescription != null || vm.captions.isNotEmpty)) {
                              nav.push(MaterialPageRoute(builder: (_) => const ResultScreen()));
                            } else if (vm.error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(vm.error!), behavior: SnackBarBehavior.floating),
                              );
                            }
                          },
                        ),
                        
                        const SizedBox(height: 140), // Bottom padding for navbar
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky Banner Ad at bottom (above navbar)
          if (banner != null)
            Positioned(
              bottom: 100, // Above floating navbar
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

class _ImagePickerContainer extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const _ImagePickerContainer({this.imageBytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: imageBytes == null 
              ? Border.all(color: theme.colorScheme.primary.withOpacity(0.1), width: 2)
              : null,
          image: imageBytes != null 
              ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover)
              : null,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_photo_alternate_rounded, size: 40, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text("Tap to select a photo", style: theme.textTheme.titleMedium),
                  Text("JPG or PNG up to 10MB", style: theme.textTheme.bodySmall),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DailyLimitBadge extends StatelessWidget {
  final CaptionProvider vm;
  const _DailyLimitBadge({required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<int>(
      future: vm.remainingToday(),
      builder: (context, snap) {
        final remaining = snap.data ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                "$remaining Left",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: size / 2, spreadRadius: size / 4)],
      ),
    );
  }
}

class _CaptionEngineControls extends StatelessWidget {
  final TextEditingController keywordsController;
  const _CaptionEngineControls({required this.keywordsController});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaptionProvider>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(text: 'Category'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: CaptionCategory.values.map((cat) {
            final isSelected = vm.selectedCategory == cat;
            return _ModernChip(
              label: _catLabel(cat),
              selected: isSelected,
              onTap: () => vm.setCategory(cat),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _Label(text: 'Length'),
        const SizedBox(height: 12),
        Row(
          children: CaptionLength.values.map((len) {
            final isSelected = vm.selectedLength == len;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ModernChip(
                  label: _lenLabel(len),
                  selected: isSelected,
                  expand: true,
                  onTap: () => vm.setLength(len),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _Label(text: 'Contextual Keywords'),
        const SizedBox(height: 12),
        TextField(
          controller: keywordsController,
          decoration: InputDecoration(
            hintText: 'e.g. sunset, vibing, nature',
            filled: true,
            fillColor: theme.brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  String _catLabel(CaptionCategory c) {
    switch (c) {
      case CaptionCategory.men: return '💪 Men';
      case CaptionCategory.women: return '🌸 Women';
      case CaptionCategory.savage: return '🔥 Savage';
      case CaptionCategory.romantic: return '🌹 Romantic';
      case CaptionCategory.funny: return '😂 Funny';
      case CaptionCategory.travel: return '✈️ Travel';
      case CaptionCategory.aesthetic: return '✨ Aesthetic';
      case CaptionCategory.fitness: return '🏋️ Fitness';
      case CaptionCategory.attitude: return '😎 Attitude';
      case CaptionCategory.none: return '🚫 None';
    }
  }

  String _lenLabel(CaptionLength l) {
    switch (l) {
      case CaptionLength.short: return 'Short';
      case CaptionLength.medium: return 'Medium';
      case CaptionLength.long: return 'Long';
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1));
  }
}

class _ModernChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;

  const _ModernChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: expand ? Alignment.center : null,
        decoration: BoxDecoration(
          color: selected ? primary : (theme.brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? primary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
