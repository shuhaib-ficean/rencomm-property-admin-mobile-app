import 'package:flutter/material.dart';

class PaginatedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final bool hasReachedMax;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final Widget? emptyStateWidget;
  final EdgeInsetsGeometry padding;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    this.hasReachedMax = false,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.emptyStateWidget,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: emptyStateWidget ?? const Text('No items found'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            // Reached the end of the loaded items
            if (!isLoadingMore && !hasReachedMax) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onLoadMore();
              });
            }
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            );
          }

          return itemBuilder(context, items[index]);
        },
      ),
    );
  }
}
