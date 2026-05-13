import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../models/favorite_entry.dart';
import '../utils/ui_helpers.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites();
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
    final vm = context.watch<FavoritesProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        actions: [
          if (vm.favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => vm.clearFavorites(),
            ),
        ],
      ),
      body: SafeArea(
        child: vm.favorites.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                itemCount: vm.favorites.length,
                itemBuilder: (context, index) {
                  final entry = vm.favorites[index];
                  final imageBytes = _decodeImage(entry.imageBase64);
                  
                  return _FavoriteListCard(
                    entry: entry,
                    imageBytes: imageBytes,
                    onTap: () => _showFavoriteDetails(context, entry, imageBytes),
                  );
                },
              ),
      ),
    );
  }

  void _showFavoriteDetails(BuildContext context, FavoriteEntry entry, Uint8List? imageBytes) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(imageBytes, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 24),
            Text(entry.caption, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.5)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    label: "Copy",
                    icon: Icons.copy_rounded,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: entry.caption));
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                PremiumButton(
                  label: "Remove",
                  isSecondary: true,
                  onPressed: () {
                    context.read<FavoritesProvider>().removeFavorite(entry.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FavoriteListCard extends StatelessWidget {
  final FavoriteEntry entry;
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const _FavoriteListCard({required this.entry, this.imageBytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 90,
          child: Row(
            children: [
              if (imageBytes != null)
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                  child: Image.memory(
                    imageBytes!,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              if (imageBytes == null)
                Container(
                  width: 70,
                  height: 90,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                  ),
                  child: Icon(Icons.favorite_rounded, color: theme.colorScheme.primary.withOpacity(0.2), size: 24),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.caption,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.primary.withOpacity(0.3)),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_border_rounded, size: 60, color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 32),
          Text("No Favorites Yet", style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              "Heart the captions you love to see them here for quick access.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
