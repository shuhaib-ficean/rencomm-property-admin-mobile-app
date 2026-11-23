import 'dart:async';
import 'package:admin_mobile_app/core/utils/permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/searchable_dropdown.dart';
import '../../blocs/property/property_bloc.dart';
import '../../../core/models/property_model.dart';
import '../../../core/routes/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import 'edit_property_page.dart';
import 'manage_floors_rooms_page.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/app_entity_action_menu.dart';

class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});

  @override
  State<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCreatorId;
  String? _selectedCreatorName;
  String? _selectedCity;
  String? _selectedStatus;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final state = context.read<PropertyBloc>().state;
    if (state is PropertyInitial) {
      context.read<PropertyBloc>().add(const LoadProperties());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = value);
      final currentState = context.read<PropertyBloc>().state;
      bool currentVacant = false;
      if (currentState is PropertyLoaded) {
        currentVacant = currentState.vacantOnly;
      }
      context.read<PropertyBloc>().add(
            LoadProperties(
              search: value.trim().isEmpty ? null : value.trim(),
              createdById: _selectedCreatorId,
              vacantOnly: currentVacant,
            ),
          );
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
    final currentState = context.read<PropertyBloc>().state;
    bool currentVacant = false;
    if (currentState is PropertyLoaded) {
      currentVacant = currentState.vacantOnly;
    }
    context.read<PropertyBloc>().add(
          LoadProperties(
            createdById: _selectedCreatorId,
            vacantOnly: currentVacant,
          ),
        );
  }

  void _applyFilters({
    String? createdById,
    String? creatorName,
    bool? vacantOnly,
    String? city,
    String? status,
  }) {
    final currentState = context.read<PropertyBloc>().state;
    bool currentVacant = vacantOnly ??
        (currentState is PropertyLoaded ? currentState.vacantOnly : false);

    setState(() {
      _selectedCreatorId = createdById;
      _selectedCreatorName = creatorName;
      _selectedCity = city;
      _selectedStatus = status;
    });
    
    // In a real app, you would pass city and status to LoadProperties event
    context.read<PropertyBloc>().add(
          LoadProperties(
            search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
            createdById: createdById,
            vacantOnly: currentVacant,
          ),
        );
  }

  void _showFilterSheet(BuildContext context, List<PropertyModel> properties) {
    final Map<String, String> creators = {}; 
    for (final p in properties) {
      if (p.createdById != null && p.createdByName != null) {
        creators[p.createdById!] = p.createdByName!;
      }
    }

    String? tempCreatorId = _selectedCreatorId;
    String? tempCreatorName = _selectedCreatorName;
    String? tempCity = _selectedCity;
    String? tempStatus = _selectedStatus;
    bool tempVacantOnly = false;

    final currentState = context.read<PropertyBloc>().state;
    if (currentState is PropertyLoaded) {
      tempVacantOnly = currentState.vacantOnly;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 12,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempCreatorId = null;
                          tempCreatorName = null;
                          tempCity = null;
                          tempStatus = null;
                          tempVacantOnly = false;
                        });
                      },
                      child: Text(
                        'Reset All',
                        style: GoogleFonts.montserrat(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(
                    AppLocalizations.of(context)!.vacant,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Show only properties with vacant rooms',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  value: tempVacantOnly,
                  activeThumbColor: Colors.blue,
                  onChanged: (value) {
                    setModalState(() {
                      tempVacantOnly = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                SearchableDropdown<String>(
                  value: tempCreatorId,
                  label: 'Created By',
                  hint: 'Select Creator',
                  prefixIcon: Icons.person_outline,
                  items: {
                    null: 'All Creators',
                    ...creators,
                  },
                  onChanged: (value) {
                    setModalState(() {
                      tempCreatorId = value;
                      tempCreatorName = value != null ? creators[value] : null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SearchableDropdown<String>(
                  value: tempCity,
                  label: 'City',
                  hint: 'Filter by City',
                  prefixIcon: Icons.location_city,
                  items: const {
                    null: 'All Cities',
                    'Doha': 'Doha',
                    'The Pearl': 'The Pearl',
                    'Lusail': 'Lusail',
                    'Al Rayyan': 'Al Rayyan',
                    'Al Wakrah': 'Al Wakrah',
                  },
                  onChanged: (value) => setModalState(() => tempCity = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: tempStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) => setModalState(() => tempStatus = val),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters(
                      createdById: tempCreatorId,
                      creatorName: tempCreatorName,
                      vacantOnly: tempVacantOnly,
                      city: tempCity,
                      status: tempStatus,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.properties,
            style: GoogleFonts.montserrat(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<PropertyBloc, PropertyState>(
        listener: (context, state) {
          if (state is PropertyOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is PropertyLoaded && state.operationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.operationError!),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is PropertyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<PropertyBloc, PropertyState>(
          builder: (context, state) {
            if (state is PropertyLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PropertyLoaded) {
              
              // Apply filters
              var displayProperties = state.properties;
              if (_selectedCreatorId != null) {
                displayProperties = displayProperties
                    .where((p) => p.createdById == _selectedCreatorId)
                    .toList();
              }
              if (_selectedCity != null) {
                final cityLower = _selectedCity!.toLowerCase();
                displayProperties = displayProperties.where((p) {
                  final inCity =
                      p.city != null && p.city!.toLowerCase().contains(cityLower);
                  final inAddress = p.address != null &&
                      p.address!.toLowerCase().contains(cityLower);
                  return inCity || inAddress;
                }).toList();
              }
              if (_selectedStatus != null) {
                final statusLower = _selectedStatus!.toLowerCase();
                displayProperties = displayProperties
                    .where((p) => p.status.toLowerCase() == statusLower)
                    .toList();
              }

              final hasActiveFilters = _selectedCreatorId != null ||
                  state.vacantOnly ||
                  _selectedCity != null ||
                  _selectedStatus != null;

              return Column(
                children: [
                  // Search Bar + Filter Button
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search by name or address…',
                              hintStyle: GoogleFonts.montserrat(
                                  fontSize: 13, color: Colors.grey[400]),
                              prefixIcon:
                                  const Icon(Icons.search, color: Color(0xFF2F92D0), size: 21),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: Colors.grey),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF7F7F7),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFEBEBEB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFEBEBEB)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  _showFilterSheet(context, state.properties),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFEBEBEB)),
                                ),
                                child: const Icon(Icons.tune,
                                    color: Color(0xFF222222), size: 20),
                              ),
                            ),
                            if (hasActiveFilters)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Active Filter Pills
                  if (hasActiveFilters)
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (state.vacantOnly)
                              _buildActiveFilterChip(
                                label: 'Vacant Only',
                                onDeleted: () =>
                                    _applyFilters(vacantOnly: false),
                              ),
                            if (_selectedCity != null)
                              _buildActiveFilterChip(
                                label: 'City: $_selectedCity',
                                onDeleted: () => _applyFilters(city: null),
                              ),
                            if (_selectedStatus != null)
                              _buildActiveFilterChip(
                                label: 'Status: $_selectedStatus',
                                onDeleted: () => _applyFilters(status: null),
                              ),
                            if (_selectedCreatorName != null)
                              _buildActiveFilterChip(
                                label: 'By: $_selectedCreatorName',
                                onDeleted: () => _applyFilters(
                                    createdById: null, creatorName: null),
                              ),
                            TextButton(
                              onPressed: () => _applyFilters(
                                createdById: null,
                                creatorName: null,
                                vacantOnly: false,
                                city: null,
                                status: null,
                              ),
                              child: const Text('Clear All',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Property Count Bar
                  if (displayProperties.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${displayProperties.length} ${displayProperties.length == 1 ? "Property" : "Properties"}',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          if (state.vacantOnly)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Vacant Only',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Property Cards List / Empty State
                  Expanded(
                    child: displayProperties.isEmpty
                        ? _buildEmptyState(
                            context,
                            _searchQuery.isNotEmpty || hasActiveFilters,
                          )
                        : _buildPropertyList(context, displayProperties),
                  ),
                ],
              );
            } else if (state is PropertyError) {
              return Center(
                child: Text(AppLocalizations.of(context)!.noPropertiesFound),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      floatingActionButton:
          PermissionHelper.hasPermission(context, 'add_properties')
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.addProperty);
                  },
                  label: Text(
                    'Add Property',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  backgroundColor: const Color(0xFF2F92D0),
                  elevation: 3,
                )
              : null,
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF222222),
          ),
        ),
        backgroundColor: const Color(0xFFF7F7F7),
        deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF717171)),
        onDeleted: onDeleted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFEBEBEB)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.apartment_rounded,
                  size: 64, color: Colors.blue.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'No Matching Properties' : 'No Properties Found',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search query or filters to find what you are looking for.'
                  : 'Get started by creating your first property using the button below.',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  _clearSearch();
                  _applyFilters(
                    createdById: null,
                    creatorName: null,
                    vacantOnly: false,
                    city: null,
                    status: null,
                  );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset All Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyList(
      BuildContext context, List<PropertyModel> properties) {
    return RefreshIndicator(
      color: Colors.blue,
      onRefresh: () async {
        context.read<PropertyBloc>().add(LoadProperties(
              search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
              createdById: _selectedCreatorId,
            ));
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return _buildPropertyCard(context, property);
        },
      ),
    );
  }

  Widget _buildPropertyCard(BuildContext context, PropertyModel property) {
    int totalRooms = property.rooms.length;
    for (var f in property.floors) {
      totalRooms += f.rooms.length;
    }

    int totalOccupied = 0;
    for (var r in property.rooms) {
      if (r.activeTenantsCount > 0 ||
          r.status.toLowerCase() == 'occupied') {
        totalOccupied++;
      }
    }
    for (var f in property.floors) {
      for (var r in f.rooms) {
        if (r.activeTenantsCount > 0 ||
            r.status.toLowerCase() == 'occupied') {
          totalOccupied++;
        }
      }
    }

    int totalAvailable = (totalRooms - totalOccupied).clamp(0, totalRooms);
    double occupancyRate =
        totalRooms > 0 ? (totalOccupied / totalRooms) : 0.0;
    final bool isActive = property.status.toLowerCase() == 'active';

    final String locationText = [
      if (property.address != null && property.address!.trim().isNotEmpty)
        property.address!.trim(),
      if (property.city != null && property.city!.trim().isNotEmpty)
        property.city!.trim(),
    ].join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.propertyDetails,
                arguments: property);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clean Photo Header with Minimalist Overlays (No dark gradient overlay)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: property.images.isNotEmpty
                        ? Image.network(
                            property.images.first,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImageFallback(property),
                          )
                        : _buildImageFallback(property),
                  ),

                  // Top-Left: Minimalist Frosted Property Type Pill
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            property.type.toLowerCase() == 'villa'
                                ? Icons.holiday_village_outlined
                                : Icons.apartment_rounded,
                            size: 13,
                            color: const Color(0xFF222222),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            property.type.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF222222),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top-Right: Minimal Status Pill & 3-Dot Action Button
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : Colors.grey.shade500,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isActive ? 'Active' : 'Inactive',
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFF222222),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: _buildActionsMenu(property),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Card Body: Name & Address Prominently Highlighted (Airbnb Style)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HIGHLIGHTED HERO: Property Name
                    Text(
                      property.name,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF222222),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // HIGHLIGHTED HERO: Address / Location
                    if (locationText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: Color(0xFF717171),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationText,
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFF717171),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (property.description != null &&
                        property.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        property.description!.trim(),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: const Color(0xFF888888),
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // SECONDARY INFORMATION: Minimalist, clean neutral strip (No loud multi-colors)
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEBEBEB)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMinimalStatItem(
                              title: '${property.floors.length} Floors',
                              subtitle: '$totalRooms Total Units',
                              icon: Icons.layers_outlined,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            color: const Color(0xFFE0E0E0),
                          ),
                          Expanded(
                            child: _buildMinimalStatItem(
                              title: '$totalOccupied Occupied',
                              subtitle: totalRooms > 0
                                  ? '${(occupancyRate * 100).toInt()}% full'
                                  : '0%',
                              icon: Icons.people_outline,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            color: const Color(0xFFE0E0E0),
                          ),
                          Expanded(
                            child: _buildMinimalStatItem(
                              title: totalAvailable > 0
                                  ? '$totalAvailable Vacant'
                                  : 'Occupied',
                              subtitle: totalAvailable > 0
                                  ? 'Available'
                                  : 'No Vacancy',
                              icon: Icons.door_front_door_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Minimal Occupancy Status Indicator
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Occupancy Status',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF717171),
                          ),
                        ),
                        Text(
                          '$totalOccupied of $totalRooms units (${(occupancyRate * 100).toInt()}%)',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF222222),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: totalRooms > 0 ? occupancyRate : 0.0,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFEBEBEB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2F92D0),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 10),

                    // Minimal Footer Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (property.managerName != null &&
                            property.managerName!.trim().isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 13, color: Color(0xFF717171)),
                              const SizedBox(width: 4),
                              Text(
                                'Manager: ${property.managerName}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: const Color(0xFF717171),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        else if (property.createdByName != null)
                          Text(
                            'By ${property.createdByName}',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: const Color(0xFF717171),
                            ),
                          )
                        else if (property.currency != null &&
                            property.currency!.isNotEmpty)
                          Text(
                            'Currency: ${property.currency}',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: const Color(0xFF717171),
                            ),
                          )
                        else
                          const SizedBox.shrink(),

                        // Clean View Details Action
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2F92D0),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: Color(0xFF2F92D0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalStatItem({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF717171)),
        const SizedBox(height: 3),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF222222),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF717171),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImageFallback(PropertyModel property) {
    final isVilla = property.type.toLowerCase() == 'villa';
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFFF7F7F7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVilla ? Icons.holiday_village_outlined : Icons.apartment_rounded,
              size: 40,
              color: const Color(0xFFBBBBBB),
            ),
            const SizedBox(height: 6),
            Text(
              property.type.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF999999),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsMenu(PropertyModel property) {
    final isActive = property.status == 'Active';
    return AppEntityActionMenu(
      iconColor: const Color(0xFF222222),
      onView: () {
        Navigator.pushNamed(context, AppRoutes.propertyDetails,
            arguments: property);
      },
      viewLabel: 'View Details',
      onEdit: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditPropertyPage(property: property)));
      },
      editLabel: 'Edit Property',
      isActive: isActive,
      onToggleStatus: () {
        if (isActive) {
          if (property.hasActiveTenants) {
            _showCannotInactivateDialog(context);
          } else {
            _showActionDialog(property, 'Inactivate',
                'Are you sure you want to inactivate "${property.name}"?');
          }
        } else {
          _showActionDialog(property, 'Activate',
              'Are you sure you want to activate "${property.name}"?');
        }
      },
      customActions: [
        AppActionMenuItem(
          label: 'Manage Floors & Units',
          icon: Icons.dashboard_customize_outlined,
          color: Colors.teal[700],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ManageFloorsRoomsPage(property: property),
              ),
            );
          },
        ),
        AppActionMenuItem(
          label: 'Add Floor',
          icon: Icons.layers_outlined,
          color: Colors.blueGrey[700],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageFloorsRoomsPage(
                  property: property,
                  openAddFloorOnLaunch: true,
                ),
              ),
            );
          },
        ),
        AppActionMenuItem(
          label: 'Add Room',
          icon: Icons.meeting_room_outlined,
          color: Colors.blueGrey[700],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageFloorsRoomsPage(
                  property: property,
                  openAddRoomOnLaunch: true,
                ),
              ),
            );
          },
        ),
      ],
      onDelete: () {
        _showActionDialog(property, 'Delete',
            'Are you sure you want to permanently delete "${property.name}"? This action cannot be undone.',
            isDestructive: true);
      },
      deleteLabel: 'Delete Property',
    );
  }

  void _showCannotInactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cannot Inactivate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Cannot inactivate this property because there are active tenants occupying units. Please vacate or reassign all tenants before setting the property to inactive.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showActionDialog(PropertyModel property, String actionTitle, String content, {bool isDestructive = false}) {
    ConfirmationDialog.show(
      context: context,
      title: actionTitle,
      content: content,
      confirmText: actionTitle,
      cancelText: 'Cancel',
      isDestructive: isDestructive,
      onConfirm: () {
        if (actionTitle == 'Delete') {
          context.read<PropertyBloc>().add(DeleteProperty(property.id));
        } else if (actionTitle == 'Activate' || actionTitle == 'Inactivate') {
          if (actionTitle == 'Inactivate' && property.hasActiveTenants) {
            _showCannotInactivateDialog(context);
            return;
          }
          final newStatus = actionTitle == 'Activate' ? 'Active' : 'Inactive';
          final updatedData = property.toJson();
          updatedData['status'] = newStatus;
          context.read<PropertyBloc>().add(UpdateProperty(property.id, updatedData));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$actionTitle action dispatched (Mocked)')));
        }
      },
    );
  }
}
