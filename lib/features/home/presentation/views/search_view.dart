import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> popularSearches = [
    'Biryani',
    'Burgers',
    'Pizza',
    'Death by Chocolate',
    'Leon\'s',
    'Kabab',
    'Chicken Wings',
    'Ice Cream',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (query.trim().isEmpty) return;

    // TODO: Trigger your Riverpod search provider here
    // ref.read(searchProvider.notifier).search(query);
    debugPrint("Searching for: $query");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // UX Improvement: Dismiss keyboard when tapping empty space
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Search',
            style: AppTextStyles.heading2.copyWith(fontSize: 16),
          ),
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
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _performSearch,
                  onChanged: (value) {
                    // Triggers a rebuild to show/hide the clear icon
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for restaurants, cuisines or dishes',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    // UX Improvement: Dynamic clear button
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              // Optional: ref.read(searchProvider.notifier).clearSearch();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Popular Searches Title
              Text(
                'Popular Searches',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Grid / Wrap of tags
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: popularSearches
                    .map((tag) => _buildSearchTag(tag))
                    .toList(),
              ),

              const Spacer(),

              // Placeholder Info
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_outlined,
                      size: 64,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Search Module Coming Soon',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTag(String tag) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Auto-fill the search bar and trigger the search
          _searchController.text = tag;
          _performSearch(tag);
          setState(() {}); // Update the clear icon visibility
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.trending_up, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                tag,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
