import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/caption_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/favorite_entry.dart';
import '../utils/ui_helpers.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CaptionProvider>().loadHistory();
    });
  }

  Uint8List? _decodeImage(String? base64) {
    if (base64 == null || base64.trim().isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaptionProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent History"),
        actions: [
          if (vm.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => vm.clearHistory(),
              tooltip: "Clear All",
            ),
        ],
      ),
      body: SafeArea(
        child: vm.history.isEmpty
            ? _EmptyState(
                icon: Icons.history_rounded,
                title: "No history yet",
                subtitle: "Captions you generate will appear here.",
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                itemCount: vm.history.length,
                itemBuilder: (context, index) {
                  return _HistoryItem(
                    entry: vm.history[index],
                    imageBytes: _decodeImage(vm.history[index].imageBase64),
                    formatDate: _formatDate,
                  );
                },
              ),
      ),
    );
  }

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${time.day}/${time.month}/${time.year}";
  }
}

class _HistoryItem extends StatefulWidget {
  final dynamic entry; // Use your model type if available, but dynamic works for generic
  final Uint8List? imageBytes;
  final String Function(DateTime) formatDate;

  const _HistoryItem({
    required this.entry,
    this.imageBytes,
    required this.formatDate,
  });

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favVm = context.watch<FavoritesProvider>();
    final entry = widget.entry;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageBytes != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.memory(
                  widget.imageBytes!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.formatDate(entry.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_all_rounded, size: 20),
                        tooltip: "Copy All",
                        onPressed: () {
                          final allText = entry.captions.join("\n");
                          Clipboard.setData(ClipboardData(text: allText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("All captions copied")),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.description,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                    maxLines: _isExpanded ? 10 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // Expandable Section
                  AnimatedCrossFade(
                    firstChild: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.captions.take(3).map<Widget>((c) => _MiniCaptionTag(text: c)).toList(),
                    ),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        ...entry.captions.map<Widget>((caption) {
                          final id = caption.hashCode.toRadixString(16);
                          final isFav = favVm.isFavorite(id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    caption,
                                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 16,
                                    color: isFav ? Colors.redAccent : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    if (isFav) {
                                      await favVm.removeFavorite(id);
                                    } else {
                                      await favVm.addFavorite(
                                        FavoriteEntry(
                                          id: id,
                                          caption: caption,
                                          imageBase64: entry.imageBase64,
                                          savedAt: DateTime.now(),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: caption));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Caption copied")),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                    crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Toggle Button
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isExpanded ? "Show Less" : "Show All ${entry.captions.length} Captions",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
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

class _MiniCaptionTag extends StatelessWidget {
  final String text;
  const _MiniCaptionTag({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: theme.colorScheme.primary.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}