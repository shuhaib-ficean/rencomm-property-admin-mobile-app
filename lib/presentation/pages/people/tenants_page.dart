import 'dart:async';

import 'package:admin_mobile_app/core/utils/permission_helper.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/searchable_dropdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/tenant/tenant_bloc.dart';
import '../../blocs/property/property_bloc.dart';
import '../../../core/models/tenant_model.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/assign_property_modal.dart';
import '../../widgets/app_entity_action_menu.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/paginated_list_view.dart';
import 'add_person_page.dart';

class TenantsPage extends StatefulWidget {
  const TenantsPage({super.key});

  @override
  State<TenantsPage> createState() => _TenantsPageState();
}

class _TenantsPageState extends State<TenantsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPropertyId;
  String? _selectedPropertyName;
  String? _selectedCreatorId;
  String? _selectedCreatorName;
  Timer? _debounce;

  bool get _hasActiveFilter =>
      _selectedPropertyId != null || _selectedCreatorId != null;

  @override
  void initState() {
    super.initState();
    context.read<TenantBloc>().add(const LoadTenants());
    // Load properties for the filter dropdown
    context.read<PropertyBloc>().add(const LoadProperties());
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
      context.read<TenantBloc>().add(LoadTenants(
            search: value.trim().isEmpty ? null : value.trim(),
            propertyId: _selectedPropertyId,
            createdById: _selectedCreatorId,
          ));
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
    context.read<TenantBloc>().add(LoadTenants(
          propertyId: _selectedPropertyId,
          createdById: _selectedCreatorId,
        ));
  }

  void _applyFilters(String? propertyId, String? propertyName,
      String? creatorId, String? creatorName) {
    setState(() {
      _selectedPropertyId = propertyId;
      _selectedPropertyName = propertyName;
      _selectedCreatorId = creatorId;
      _selectedCreatorName = creatorName;
    });
    context.read<TenantBloc>().add(LoadTenants(
          search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
          propertyId: propertyId,
          createdById: creatorId,
        ));
  }

  void _showFilterSheet(BuildContext ctx, List<TenantModel> tenants) {
    // Collect unique creators from loaded tenants
    final Map<String, String> creators = {};
    for (final t in tenants) {
      if (t.createdById != null && t.createdByName != null) {
        creators[t.createdById!] = t.createdByName!;
      }
    }

    String? tempPropertyId = _selectedPropertyId;
    String? tempPropertyName = _selectedPropertyName;
    String? tempCreatorId = _selectedCreatorId;
    String? tempCreatorName = _selectedCreatorName;

    showModalBottomSheet(
      context: ctx,
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
                          tempPropertyId = null;
                          tempPropertyName = null;
                          tempCreatorId = null;
                          tempCreatorName = null;
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
                const SizedBox(height: 20),
                // Property searchable dropdown
                BlocBuilder<PropertyBloc, PropertyState>(
                  builder: (context, state) {
                    final Map<String?, String> propertyItems = {
                      null: 'All Properties',
                    };
                    if (state is PropertyLoaded) {
                      for (final p in state.properties) {
                        propertyItems[p.id] = p.name;
                      }
                    }
                    return SearchableDropdown<String>(
                      value: tempPropertyId,
                      label: 'Property',
                      hint: 'Select Property',
                      prefixIcon: Icons.business_outlined,
                      items: propertyItems,
                      onChanged: (value) {
                        setModalState(() {
                          tempPropertyId = value;
                          tempPropertyName =
                              value != null ? propertyItems[value] : null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Created By searchable dropdown
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters(tempPropertyId, tempPropertyName,
                        tempCreatorId, tempCreatorName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TenantBloc, TenantState>(
      listener: (context, state) {
        if (state is TenantOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.green),
          );
        } else if (state is TenantLoaded) {
          if (state.operationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.operationError!),
                  backgroundColor: Colors.red),
            );
          } else if (state.operationSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.operationSuccess!),
                  backgroundColor: Colors.green),
            );
          }
        } else if (state is TenantError && state.isOperationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.tenants,
              style: GoogleFonts.montserrat(
                  color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocBuilder<TenantBloc, TenantState>(
          builder: (context, state) {
            if (state is TenantLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TenantLoaded) {
              return Column(
                children: [
                  // Search bar + filter button
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search by name, phone, email, or QID…',
                              hintStyle: GoogleFonts.montserrat(
                                  fontSize: 13, color: const Color(0xFFB0B0B0)),
                              prefixIcon:
                                  const Icon(Icons.search, color: Color(0xFF2F92D0), size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: Color(0xFF717171), size: 18),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF7F7F7),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFEBEBEB), width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFEBEBEB), width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2F92D0), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Filter button with red dot badge
                        Stack(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  _showFilterSheet(context, state.tenants),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.tune,
                                    color: Colors.black54, size: 22),
                              ),
                            ),
                            if (_hasActiveFilter)
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
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  // Tenant list
                  Expanded(
                    child: state.tenants.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty || _hasActiveFilter
                                  ? 'No tenants match your search or filters'
                                  : AppLocalizations.of(context)!
                                      .noTenantsFound,
                              style: GoogleFonts.montserrat(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : PaginatedListView<TenantModel>(
                            items: state.tenants,
                            isLoadingInitial:
                                false, // loading state handled above
                            isLoadingMore: state.isLoadingMore,
                            hasReachedMax: state.hasReachedMax,
                            onRefresh: () async {
                              context
                                  .read<TenantBloc>()
                                  .add(const LoadTenants(isRefresh: true));
                              setState(() {
                                _searchQuery = '';
                                _selectedPropertyId = null;
                                _selectedPropertyName = null;
                                _selectedCreatorId = null;
                                _selectedCreatorName = null;
                                _searchController.clear();
                              });
                            },
                            onLoadMore: () {
                              context.read<TenantBloc>().add(LoadTenants(
                                    isLoadMore: true,
                                    search: _searchQuery.trim().isEmpty
                                        ? null
                                        : _searchQuery.trim(),
                                    propertyId: _selectedPropertyId,
                                    createdById: _selectedCreatorId,
                                  ));
                            },
                            emptyStateWidget: Center(
                              child: Text(
                                _searchQuery.isNotEmpty || _hasActiveFilter
                                    ? 'No tenants match your search or filters'
                                    : AppLocalizations.of(context)!
                                        .noTenantsFound,
                                style: GoogleFonts.montserrat(
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            itemBuilder: (context, tenant) {
                              return _buildPersonCard(
                                context,
                                name: tenant.name,
                                role:
                                    '${AppLocalizations.of(context)!.property}: ${tenant.property != null ? "${tenant.property!.name}${tenant.assignedRoom?.number != null ? ' - ${tenant.assignedRoom?.number}' : ''}" : AppLocalizations.of(context)!.notAssigned}',
                                status: tenant.status,
                                phone: tenant.phone,
                                email: tenant.email,
                                qatarId: tenant.qatarId,
                                imageUrl:
                                    'https://www.gravatar.com/avatar/${tenant.email}?d=https%3A%2F%2Fui-avatars.com%2Fapi%2F/${tenant.name}/128',
                                balanceAmount: tenant.financials?.totalPaid,
                                pendingAmount: tenant.financials?.totalPending,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.personDetails,
                                    arguments: tenant,
                                  );
                                },
                                onDocuments: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.tenantDocuments,
                                    arguments: tenant,
                                  );
                                  if (context.mounted) {
                                    context
                                        .read<TenantBloc>()
                                        .add(const LoadTenants());
                                  }
                                },
                                onEdit: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddPersonPage(person: tenant),
                                    ),
                                  );
                                  if (context.mounted) {
                                    context
                                        .read<TenantBloc>()
                                        .add(const LoadTenants());
                                  }
                                },
                                onDelete: () {
                                  _showDeleteConfirmation(context, tenant);
                                },
                                onToggleStatus: () {
                                  final isCurrentlyActive = tenant.status.toLowerCase() == 'active';
                                  ConfirmationDialog.show(
                                    context: context,
                                    title: isCurrentlyActive ? 'Inactivate Tenant' : 'Activate Tenant',
                                    content: 'Are you sure you want to ${isCurrentlyActive ? 'inactivate' : 'activate'} "${tenant.name}"?',
                                    confirmText: isCurrentlyActive ? 'Inactivate' : 'Activate',
                                    cancelText: AppLocalizations.of(context)!.cancel,
                                    isDestructive: isCurrentlyActive,
                                    icon: isCurrentlyActive
                                        ? Icons.pause_circle_outline_rounded
                                        : Icons.check_circle_outline_rounded,
                                    confirmColor: isCurrentlyActive ? Colors.orange[800] : Colors.green[700],
                                    onConfirm: () {
                                      context.read<TenantBloc>().add(UpdateTenant(
                                        tenant.id,
                                        {'status': isCurrentlyActive ? 'inactive' : 'active'},
                                      ));
                                    },
                                  );
                                },
                                onCall: () {
                                  _makePhoneCall(tenant.phone);
                                },
                                onAssign: (tenant.assignedRoom == null ||
                                        tenant.property == null)
                                    ? () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AssignPropertyModal(
                                              tenantId: tenant.id),
                                        );
                                      }
                                    : null,
                                onUnassign: (tenant.assignedRoom != null &&
                                        tenant.property != null)
                                    ? () {
                                        ConfirmationDialog.show(
                                          context: context,
                                          title: AppLocalizations.of(context)!
                                              .unassign,
                                          content: AppLocalizations.of(context)!
                                              .unassignConfirmation,
                                          confirmText:
                                              AppLocalizations.of(context)!
                                                  .unassign,
                                          cancelText:
                                              AppLocalizations.of(context)!
                                                  .cancel,
                                          isDestructive: true,
                                          onConfirm: () {
                                            context
                                                .read<TenantBloc>()
                                                .add(UnassignRoom(
                                                  tenant.id,
                                                  tenant.assignedRoom!.id,
                                                  tenant.property!.id,
                                                ));
                                          },
                                        );
                                      }
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              );
            } else if (state is TenantError && !state.isOperationError) {
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<TenantBloc>()
                      .add(const LoadTenants(isRefresh: true));
                },
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.error_outline_rounded,
                                    color: Colors.red, size: 36),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Unable to Load Tenants',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context
                                      .read<TenantBloc>()
                                      .add(const LoadTenants(isRefresh: true));
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
        floatingActionButton:
            PermissionHelper.hasPermission(context, 'add_tenants')
                ? FloatingActionButton(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/add-person',
                          arguments: {'initialRole': AppConstants.tenant});
                      if (context.mounted) {
                        context.read<TenantBloc>().add(const LoadTenants());
                      }
                    },
                    backgroundColor: const Color(0xFF2F92D0),
                    child: const Icon(Icons.person_add, color: Colors.white),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TenantModel tenant) {
    ConfirmationDialog.show(
      context: context,
      title: AppLocalizations.of(context)!.delete,
      content: AppLocalizations.of(context)!.deletePersonConfirmation,
      confirmText: AppLocalizations.of(context)!.delete,
      cancelText: AppLocalizations.of(context)!.cancel,
      isDestructive: true,
      onConfirm: () {
        context.read<TenantBloc>().add(DeleteTenant(tenant.id));
      },
    );
  }

  Widget _buildPersonCard(
    BuildContext context, {
    required String name,
    required String role,
    required String status,
    String? phone,
    String? email,
    String? qatarId,
    required String imageUrl,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onToggleStatus,
    VoidCallback? onCall,
    VoidCallback? onAssign,
    VoidCallback? onUnassign,
    VoidCallback? onDocuments,
    double? balanceAmount,
    double? pendingAmount,
  }) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(imageUrl),
                  backgroundColor: const Color(0xFFF7F7F7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.home_work_outlined, size: 14, color: Color(0xFF717171)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            role,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFF717171),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 13, color: Color(0xFFB0B0B0)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              phone,
                              style: GoogleFonts.montserrat(
                                  fontSize: 12, color: const Color(0xFF717171)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              size: 13, color: Color(0xFFB0B0B0)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              email,
                              style: GoogleFonts.montserrat(
                                  fontSize: 12, color: const Color(0xFF717171)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (qatarId != null && qatarId.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined,
                              size: 13, color: Color(0xFFB0B0B0)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'QID: $qatarId',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF717171)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFEBEBEB), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: status.toLowerCase() == 'active'
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF717171),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                status,
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFF222222),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (pendingAmount != null && pendingAmount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFEE2E2), width: 0.8),
                            ),
                            child: Text(
                              'Due: QR ${pendingAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFFDC2626),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (balanceAmount != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              size: 12, color: Color(0xFFB0B0B0)),
                          const SizedBox(width: 4),
                          Text(
                            'Paid: QR ${balanceAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: const Color(0xFF717171),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onCall != null)
                Container(
                  height: 32,
                  width: 32,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F92D0).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    color: const Color(0xFF2F92D0),
                    onPressed: onCall,
                    padding: EdgeInsets.zero,
                  ),
                ),
              AppEntityActionMenu(
                onView: onTap,
                onEdit: PermissionHelper.hasPermission(context, 'edit_tenants')
                    ? onEdit
                    : null,
                editLabel: AppLocalizations.of(context)!.edit,
                isActive: status.toLowerCase() == 'active',
                onToggleStatus:
                    PermissionHelper.hasPermission(context, 'edit_tenants')
                        ? onToggleStatus
                        : null,
                customActions: [
                  if (PermissionHelper.hasPermission(context, 'edit_tenants') &&
                      onDocuments != null)
                    AppActionMenuItem(
                      label: AppLocalizations.of(context)!.updateDocuments,
                      icon: Icons.folder_outlined,
                      color: const Color(0xFF222222),
                      onTap: onDocuments,
                    ),
                  if (PermissionHelper.hasPermission(context, 'edit_tenants') &&
                      onAssign != null)
                    AppActionMenuItem(
                      label: AppLocalizations.of(context)!.assign,
                      icon: Icons.add_home_work_outlined,
                      color: const Color(0xFF222222),
                      onTap: onAssign,
                    ),
                  if (PermissionHelper.hasPermission(context, 'edit_tenants') &&
                      onUnassign != null)
                    AppActionMenuItem(
                      label: AppLocalizations.of(context)!.unassign,
                      icon: Icons.remove_circle_outline,
                      color: const Color(0xFF222222),
                      onTap: onUnassign,
                    ),
                ],
                onDelete: PermissionHelper.hasPermission(
                        context, 'delete_tenants')
                    ? onDelete
                    : null,
                deleteLabel: AppLocalizations.of(context)!.delete,
              ),
            ],
          ),
        ));
  }
}
