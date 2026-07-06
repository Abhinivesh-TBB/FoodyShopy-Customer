import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final popularSearches = ['Biryani', 'Burgers', 'Pizza', 'Death by Chocolate', 'Leon\'s', 'Kabab', 'Chicken Wings', 'Ice Cream'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Search', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Box
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search for restaurants, cuisines or dishes',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Popular Searches Title
            Text(
              'Popular Searches',
              style: AppTextStyles.heading2.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Grid / Wrap of tags
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: popularSearches.map((tag) => _buildSearchTag(tag)).toList(),
            ),

            const Spacer(),

            // Placeholder Info
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_outlined, size: 64, color: Colors.grey[200]),
                  const SizedBox(height: 12),
                  const Text(
                    'Search Module Coming Soon',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
