import 'package:admin_mobile_app/core/utils/permission_helper.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:admin_mobile_app/presentation/blocs/staff/staff_bloc.dart';
import '../../blocs/role/role_bloc.dart';
import 'add_role_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/models/role_model.dart';

class RoleDetailsPage extends StatefulWidget {
  final RoleModel role;

  const RoleDetailsPage({super.key, required this.role});

  @override
  State<RoleDetailsPage> createState() => _RoleDetailsPageState();
}

class _RoleDetailsPageState extends State<RoleDetailsPage> {
  // Grouped permissions map (same as AddRolePage but for display)
  final Map<String, List<String>> _groupedPermissionsMap = {
    'Dashboard & Analytics': ['view_analytics'],
    'Properties': [
      'view_properties',
      'add_properties',
      'edit_properties',
      'delete_properties',
    ],
    'Tenants': [
      'view_tenants',
      'add_tenants',
      'edit_tenants',
      'delete_tenants',
    ],
    'Staff': [
      'view_staffs',
      'add_staffs',
      'edit_staffs',
      'delete_staffs',
    ],
    'Payments': [
      'view_payments',
      'add_payments',
      'edit_payments',
      'delete_payments',
    ],
    'Settings': ['manage_roles', 'change_password'],
    'Amenities': [
      'view_amenities',
      'add_amenities',
      'edit_amenities',
      'delete_amenities',
    ],
  };

  @override
  void initState() {
    super.initState();
    // Load staff to see who has this role
    context.read<StaffBloc>().add(const LoadStaff());
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Dashboard & Analytics':
        return Icons.dashboard;
      case 'Properties':
        return Icons.house;
      case 'Tenants':
        return Icons.person;
      case 'Staff':
        return Icons.badge;
      case 'Payments':
        return Icons.payment;
      case 'Settings':
        return Icons.settings;
      case 'Amenities':
        return Icons.handyman;
      default:
        return Icons.lock;
    }
  }

  String _formatPermissionName(String permission) {
    return permission.replaceAll('_', ' ').capitalize();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, state) {
        // Find the updated role object from the state if available
        RoleModel currentRole = widget.role;
        if (state is RoleLoaded) {
          try {
            currentRole = state.roles.firstWhere((r) => r.id == widget.role.id);
          } catch (e) {
            // Role might have been deleted or not found
          }
        }

        final permissions = currentRole.permissions;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              currentRole.name,
              style: GoogleFonts.montserrat(
                  color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              if (PermissionHelper.hasPermission(context, 'manage_roles'))
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddRolePage(role: currentRole),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.description,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentRole.description ??
                            AppLocalizations.of(context)!.noDescriptionProvided,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Permissions Section
                Text(
                  AppLocalizations.of(context)!.permissions,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._groupedPermissionsMap.entries.map((entry) {
                  final category = entry.key;
                  final categoryPermissions = entry.value;
                  // Filter permissions that this role actually has
                  final roleHasPermissions = categoryPermissions
                      .where((p) => permissions.contains(p))
                      .toList();

                  if (roleHasPermissions.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Row(
                          children: [
                            Icon(_getCategoryIcon(category),
                                color: const Color(0xFF2F92D0)),
                            const SizedBox(width: 12),
                            Text(
                              category,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${roleHasPermissions.length}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: roleHasPermissions.map((p) {
                                return Chip(
                                  label: Text(
                                    _formatPermissionName(p),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  backgroundColor: Colors.blue[50],
                                  side: BorderSide.none,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Assigned People Section
                Text(
                  AppLocalizations.of(context)!.assignedStaff,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<StaffBloc, StaffState>(
                  builder: (context, state) {
                    if (state is StaffLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is StaffLoaded) {
                      final assignedStaff = state.staff
                          .where((s) => s.roleId == currentRole.id)
                          .toList();

                      if (assignedStaff.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .noStaffMembersAssignedToThisRole,
                            style: GoogleFonts.montserrat(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: assignedStaff.length,
                        itemBuilder: (context, index) {
                          final staff = assignedStaff[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  staff.name[0].toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                staff.name,
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                staff.email,
                                style: GoogleFonts.montserrat(fontSize: 12),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
                              onTap: () {
                                // Navigate to person details (optional)
                                Navigator.pushNamed(
                                  context,
                                  '/person_details',
                                  arguments: staff,
                                );
                              },
                            ),
                          );
                        },
                      );
                    } else if (state is StaffError) {
                      return Text('Failed to load staff: ${state.message}');
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
