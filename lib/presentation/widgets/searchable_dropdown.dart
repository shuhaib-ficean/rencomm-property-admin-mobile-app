import 'package:admin_mobile_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final T? value;
  final String hint;
  final String label;
  final IconData prefixIcon;
  final Map<T?, String> items;
  final Function(T?)? onChanged;

  const SearchableDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.label,
    required this.prefixIcon,
    required this.items,
    this.onChanged,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  void _showPicker() {
    if (widget.onChanged == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DropdownPicker<T>(
        hint: widget.hint,
        items: widget.items,
        initialValue: widget.value,
        onSelected: widget.onChanged!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayValue = widget.items[widget.value] ?? widget.hint;
    final bool hasValue = widget.value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray700,
            ),
          ),
        ),
        InkWell(
          onTap: widget.onChanged == null ? null : _showPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  widget.onChanged == null ? AppTheme.gray100 : AppTheme.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                Icon(widget.prefixIcon,
                    color: widget.onChanged == null
                        ? AppTheme.gray400
                        : AppTheme.primaryBlue,
                    size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayValue,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      color: widget.onChanged == null
                          ? AppTheme.gray500
                          : (hasValue ? AppTheme.gray900 : AppTheme.gray400),
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppTheme.gray400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownPicker<T> extends StatefulWidget {
  final String hint;
  final Map<T?, String> items;
  final T? initialValue;
  final Function(T?) onSelected;

  const _DropdownPicker({
    required this.hint,
    required this.items,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<_DropdownPicker<T>> createState() => _DropdownPickerState<T>();
}

class _DropdownPickerState<T> extends State<_DropdownPicker<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      return entry.value.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Ensure the current selection or "All" option remains meaningful
    // Usually, the first item is the "All" or "null" option.

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Search Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppTheme.primaryBlue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.gray50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              // List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final entry = filteredItems[index];
                    final bool isSelected = entry.key == widget.initialValue;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 4),
                      title: Text(
                        entry.value,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.gray900,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppTheme.primaryBlue)
                          : null,
                      onTap: () {
                        widget.onSelected(entry.key);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
