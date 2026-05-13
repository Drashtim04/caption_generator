import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/caption_request.dart';
import '../providers/caption_engine_provider.dart';

// ---------------------------------------------------------------------------
// CaptionEngineScreen
// ---------------------------------------------------------------------------
// Standalone screen for the advanced Caption Engine feature.
// It is accessed from HomeScreen via a new action button and does NOT
// modify any existing screen or provider.
// ---------------------------------------------------------------------------
class CaptionEngineScreen extends StatefulWidget {
  const CaptionEngineScreen({super.key});

  @override
  State<CaptionEngineScreen> createState() => _CaptionEngineScreenState();
}

class _CaptionEngineScreenState extends State<CaptionEngineScreen>
    with SingleTickerProviderStateMixin {
  final _keywordsController = TextEditingController();
  final _transformController = TextEditingController();
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _keywordsController.dispose();
    _transformController.dispose();
    _tabs.dispose();
    super.dispose();
  }

  // ---- helpers ----

  static const _primary = Color(0xFF102A43);
  static const _accent = Color(0xFF3C6E71);

  String _categoryLabel(CaptionCategory c) {
    switch (c) {
      case CaptionCategory.men:
        return 'Men 💪';
      case CaptionCategory.women:
        return 'Women 🌸';
      case CaptionCategory.savage:
        return 'Savage 🔥';
      case CaptionCategory.romantic:
        return 'Romantic 🌹';
      case CaptionCategory.funny:
        return 'Funny 😂';
    }
  }

  String _lengthLabel(CaptionLength l) {
    switch (l) {
      case CaptionLength.short:
        return 'Short';
      case CaptionLength.medium:
        return 'Medium';
      case CaptionLength.long:
        return 'Long';
    }
  }

  String _styleLabel(CaptionStyle s) {
    switch (s) {
      case CaptionStyle.humanize:
        return 'Humanize 🗣️';
      case CaptionStyle.rhyming:
        return 'Rhyming 🎵';
      case CaptionStyle.savage:
        return 'Savage 🔥';
      case CaptionStyle.funny:
        return 'Funny 😂';
      case CaptionStyle.romantic:
        return 'Romantic 🌹';
    }
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaptionEngineProvider(),
      child: Builder(builder: (ctx) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(ctx),
          body: _buildBody(ctx),
        );
      }),
    );
  }

  AppBar _buildAppBar(BuildContext ctx) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Caption Engine ✨',
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          color: _primary,
        ),
      ),
      bottom: TabBar(
        controller: _tabs,
        labelColor: _primary,
        unselectedLabelColor: const Color(0xFF7B8794),
        indicatorColor: _accent,
        tabs: const [
          Tab(text: 'Generate'),
          Tab(text: 'Transform'),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext ctx) {
    final vm = ctx.watch<CaptionEngineProvider>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F3ED), Color(0xFFE7F1F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Error banner
            if (vm.error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFE57373), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.error!,
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: const Color(0xFFC62828)),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _GenerateTab(
                    keywordsController: _keywordsController,
                    categoryLabel: _categoryLabel,
                    lengthLabel: _lengthLabel,
                    styleLabel: _styleLabel,
                  ),
                  _TransformTab(
                    transformController: _transformController,
                    styleLabel: _styleLabel,
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

// ===========================================================================
// Generate Tab
// ===========================================================================
class _GenerateTab extends StatelessWidget {
  final TextEditingController keywordsController;
  final String Function(CaptionCategory) categoryLabel;
  final String Function(CaptionLength) lengthLabel;
  final String Function(CaptionStyle) styleLabel;

  const _GenerateTab({
    required this.keywordsController,
    required this.categoryLabel,
    required this.lengthLabel,
    required this.styleLabel,
  });

  static const _primary = Color(0xFF102A43);
  static const _accent = Color(0xFF3C6E71);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaptionEngineProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ---- Category ----
        _SectionLabel(label: 'Category'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CaptionCategory.values.map((cat) {
            final selected = vm.selectedCategory == cat;
            return _ChoiceChip(
              label: categoryLabel(cat),
              selected: selected,
              onTap: () => vm.setCategory(cat),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // ---- Length ----
        _SectionLabel(label: 'Length'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: CaptionLength.values.map((len) {
            final selected = vm.selectedLength == len;
            return _ChoiceChip(
              label: lengthLabel(len),
              selected: selected,
              onTap: () => vm.setLength(len),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // ---- Keywords ----
        _SectionLabel(label: 'Keywords (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: keywordsController,
          style: GoogleFonts.dmSans(fontSize: 14, color: _primary),
          decoration: InputDecoration(
            hintText: 'e.g. sunrise, coffee, hustle',
            hintStyle: GoogleFonts.dmSans(color: const Color(0xFF7B8794)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent),
            ),
          ),
          onChanged: vm.setKeywords,
        ),

        const SizedBox(height: 16),

        // ---- Styles ----
        _SectionLabel(label: 'Styles (multi-select)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CaptionStyle.values.map((style) {
            final selected = vm.selectedStyles.contains(style);
            return _ChoiceChip(
              label: styleLabel(style),
              selected: selected,
              selectedColor: const Color(0xFF3C6E71),
              onTap: () => vm.toggleStyle(style),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // ---- AI toggle ----
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.07)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use AI Mode',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600, color: _primary),
                  ),
                  Text(
                    'Backend integration (placeholder)',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: const Color(0xFF7B8794)),
                  ),
                ],
              ),
              Switch(
                value: vm.useAI,
                activeColor: _accent,
                onChanged: (v) => vm.setUseAI(value: v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ---- Generate button ----
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: vm.loading ? null : vm.generateCaptions,
            icon: vm.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              vm.loading ? 'Generating...' : 'Generate Captions',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        // ---- Results ----
        if (vm.response.captions.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionLabel(label: 'Generated Captions (${vm.response.captions.length})'),
          const SizedBox(height: 10),
          ...vm.response.captions.map(
            (c) => _CaptionCard(caption: c, showTransformButton: true),
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
// Transform Tab
// ===========================================================================
class _TransformTab extends StatelessWidget {
  final TextEditingController transformController;
  final String Function(CaptionStyle) styleLabel;

  const _TransformTab({
    required this.transformController,
    required this.styleLabel,
  });

  static const _primary = Color(0xFF102A43);
  static const _accent = Color(0xFF3C6E71);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaptionEngineProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SectionLabel(label: 'Paste a caption to transform'),
        const SizedBox(height: 8),
        TextField(
          controller: transformController,
          maxLines: 3,
          style: GoogleFonts.dmSans(fontSize: 14, color: _primary),
          decoration: InputDecoration(
            hintText: 'Enter any caption here…',
            hintStyle: GoogleFonts.dmSans(color: const Color(0xFF7B8794)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent),
            ),
          ),
        ),

        const SizedBox(height: 16),

        _SectionLabel(label: 'Select styles to apply'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CaptionStyle.values.map((style) {
            final selected = vm.selectedStyles.contains(style);
            return _ChoiceChip(
              label: styleLabel(style),
              selected: selected,
              selectedColor: const Color(0xFF3C6E71),
              onTap: () => vm.toggleStyle(style),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: vm.loading
                ? null
                : () {
                    final text = transformController.text.trim();
                    if (text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a caption first.')),
                      );
                      return;
                    }
                    vm.transformCaption(text);
                  },
            icon: vm.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.transform),
            label: Text(
              vm.loading ? 'Transforming...' : 'Transform Caption',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        if (vm.transformedResults.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionLabel(
              label: 'Transformed Versions (${vm.transformedResults.length})'),
          const SizedBox(height: 10),

          // Original (read-only display)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7B8794),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vm.transformInput ?? '',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: const Color(0xFF52616B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          ...vm.transformedResults
              .map((c) => _CaptionCard(caption: c, showTransformButton: false)),
        ],
      ],
    );
  }
}

// ===========================================================================
// Shared Sub-widgets
// ===========================================================================

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF52616B),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = const Color(0xFF102A43),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? selectedColor : Colors.black.withOpacity(0.12),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF52616B),
          ),
        ),
      ),
    );
  }
}

class _CaptionCard extends StatelessWidget {
  final String caption;
  final bool showTransformButton;

  const _CaptionCard({
    required this.caption,
    this.showTransformButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                caption,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF102A43),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Copy button
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy, size: 18,
                      color: Color(0xFF7B8794)),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: caption));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Caption copied.')),
                    );
                  },
                ),
                // Transform shortcut
                if (showTransformButton)
                  IconButton(
                    tooltip: 'Send to Transformer',
                    icon: const Icon(Icons.transform,
                        size: 18, color: Color(0xFF3C6E71)),
                    onPressed: () {
                      context
                          .read<CaptionEngineProvider>()
                          .setTransformInput(caption);
                      // Switch to transform tab
                      DefaultTabController.of(context).animateTo(1);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
