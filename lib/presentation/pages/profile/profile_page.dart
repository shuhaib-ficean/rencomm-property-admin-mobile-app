import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:admin_mobile_app/core/theme/app_theme.dart';
import 'package:admin_mobile_app/core/utils/permission_helper.dart';
import 'package:admin_mobile_app/core/utils/storage_helper.dart';
import 'package:admin_mobile_app/core/models/user_model.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: GoogleFonts.montserrat(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'Logout',
              style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return FutureBuilder<UserModel?>(
              future: StorageHelper.getUser(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final roleLower = user?.role.toLowerCase() ?? '';
                final isStaff = roleLower == 'staff';
                final isAdmin = roleLower == 'admin';

                final String roleTitle;
                final Color badgeBg;
                final Color badgeBorder;
                final Color badgeIcon;
                final Color badgeText;
                final IconData badgeIconData;

                if (isStaff) {
                  roleTitle = 'Staff • ${user?.department ?? 'Maintenance'}';
                  badgeBg = const Color(0xFF2563EB).withValues(alpha: 0.1);
                  badgeBorder = const Color(0xFF2563EB).withValues(alpha: 0.25);
                  badgeIcon = const Color(0xFF2563EB);
                  badgeText = const Color(0xFF1E40AF);
                  badgeIconData = Icons.build_rounded;
                } else if (isAdmin) {
                  roleTitle = 'Property Administrator';
                  badgeBg = const Color(0xFF10B981).withValues(alpha: 0.1);
                  badgeBorder = const Color(0xFF10B981).withValues(alpha: 0.25);
                  badgeIcon = const Color(0xFF059669);
                  badgeText = const Color(0xFF047857);
                  badgeIconData = Icons.admin_panel_settings_rounded;
                } else if (roleLower == 'customer') {
                  roleTitle = 'Customer Account';
                  badgeBg = Colors.orange.withValues(alpha: 0.1);
                  badgeBorder = Colors.orange.withValues(alpha: 0.25);
                  badgeIcon = Colors.orange[800]!;
                  badgeText = Colors.orange[900]!;
                  badgeIconData = Icons.person_outline_rounded;
                } else {
                  roleTitle = user?.role ?? 'User';
                  badgeBg = Colors.grey.withValues(alpha: 0.12);
                  badgeBorder = Colors.grey.withValues(alpha: 0.3);
                  badgeIcon = Colors.grey[700]!;
                  badgeText = Colors.grey[800]!;
                  badgeIconData = Icons.person_outline_rounded;
                }

                return Scaffold(
                  backgroundColor: const Color(0xFFF8FAFC),
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Top Header with Gradient & Avatar
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 190,
                              decoration: BoxDecoration(
                                gradient: isStaff
                                    ? const LinearGradient(
                                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : AppTheme.primaryGradient,
                              ),
                            ),
                            Positioned(
                              bottom: -45,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                  backgroundImage: NetworkImage(
                                    'https://www.gravatar.com/avatar/${user?.name ?? "User"}?d=https%3A%2F%2Fui-avatars.com%2Fapi%2F/${user?.name ?? "User"}/128',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 55),

                        // Name & Badges
                        if (snapshot.connectionState == ConnectionState.waiting && user == null)
                          const CircularProgressIndicator()
                        else ...[
                          Text(
                            user?.name ?? 'User',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Role Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: badgeBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  badgeIconData,
                                  size: 15,
                                  color: badgeIcon,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  roleTitle,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: badgeText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Content Section: Staff "My Profile" vs Admin Management
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: isStaff && user != null
                              ? _buildStaffProfileView(context, user)
                              : _buildAdminManagementOptions(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ================= STAFF: MY PROFILE DETAILS =================
  Widget _buildStaffProfileView(BuildContext context, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('My Profile Details'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDetailTile(
                icon: Icons.person_rounded,
                label: 'Full Name',
                value: user.name.isNotEmpty ? user.name : 'N/A',
                iconColor: const Color(0xFF2F92D0),
              ),
              const Divider(height: 22, thickness: 0.8),
              _buildDetailTile(
                icon: Icons.badge_rounded,
                label: 'Employee ID',
                value: (user.employeeId != null && user.employeeId!.trim().isNotEmpty)
                    ? user.employeeId!
                    : 'Assigned by Admin',
                iconColor: const Color(0xFF2F92D0),
              ),
              const Divider(height: 22, thickness: 0.8),
              _buildDetailTile(
                icon: Icons.handyman_rounded,
                label: 'Department',
                value: (user.department != null && user.department!.trim().isNotEmpty)
                    ? user.department!
                    : 'General Maintenance',
                iconColor: const Color(0xFF2F92D0),
              ),
              const Divider(height: 22, thickness: 0.8),
              _buildDetailTile(
                icon: Icons.email_rounded,
                label: 'Email Address',
                value: user.email.isNotEmpty ? user.email : 'N/A',
                iconColor: const Color(0xFF2F92D0),
              ),
              const Divider(height: 22, thickness: 0.8),
              _buildDetailTile(
                icon: Icons.phone_rounded,
                label: 'Phone Number',
                value: user.phone.isNotEmpty ? user.phone : 'Not provided',
                iconColor: const Color(0xFF2F92D0),
              ),
              const Divider(height: 22, thickness: 0.8),
              _buildDetailTile(
                icon: Icons.verified_user_rounded,
                label: 'Account Status',
                value: user.isActive ? 'Active Staff Member' : 'Inactive',
                iconColor: user.isActive ? const Color(0xFF10B981) : Colors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Info Banner: Managed by Property Admin
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Staff Profile Notice: Staff accounts are created and managed exclusively by your Property Administrator. Contact your admin to update personal details or duties.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF1E40AF),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildProfileOption(
          icon: Icons.settings_outlined,
          title: AppLocalizations.of(context)?.settings ?? 'Settings',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
        const SizedBox(height: 10),

        // Logout Button
        _buildProfileOption(
          icon: Icons.logout_rounded,
          title: AppLocalizations.of(context)?.logout ?? 'Logout',
          isDestructive: true,
          onTap: () => _confirmLogout(context),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ================= ADMIN: MANAGEMENT OPTIONS =================
  Widget _buildAdminManagementOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(AppLocalizations.of(context)?.account ?? 'Account'),
        if (PermissionHelper.hasPermission(context, 'view_roles'))
          _buildProfileOption(
            icon: Icons.admin_panel_settings_outlined,
            title: AppLocalizations.of(context)?.manageRoles ?? 'Manage Roles',
            onTap: () => Navigator.pushNamed(context, '/roles'),
          ),
        if (PermissionHelper.hasPermission(context, 'view_staffs'))
          _buildProfileOption(
            icon: Icons.people_outline,
            title: AppLocalizations.of(context)?.manageStaffs ?? 'Manage Staffs',
            onTap: () => Navigator.pushNamed(context, '/staff'),
          ),
        if (PermissionHelper.hasPermission(context, 'view_properties'))
          _buildProfileOption(
            icon: Icons.home_work_outlined,
            title: AppLocalizations.of(context)?.manageProperties ?? 'Manage Properties',
            onTap: () => Navigator.pushNamed(context, '/properties'),
          ),
        if (PermissionHelper.hasPermission(context, 'view_staffs') ||
            PermissionHelper.hasPermission(context, 'view_roles'))
          _buildProfileOption(
            icon: Icons.corporate_fare_outlined,
            title: 'Manage Departments',
            onTap: () => Navigator.pushNamed(context, AppRoutes.departments),
          ),
        _buildProfileOption(
          icon: Icons.settings_outlined,
          title: AppLocalizations.of(context)?.settings ?? 'Settings',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
        const SizedBox(height: 24),
        _buildProfileOption(
          icon: Icons.logout_rounded,
          title: AppLocalizations.of(context)?.logout ?? 'Logout',
          isDestructive: true,
          onTap: () => _confirmLogout(context),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    final effectiveIconColor = isDestructive
        ? const Color(0xFFEF4444)
        : (iconColor ?? const Color(0xFF2F92D0));
    final textColor = isDestructive
        ? const Color(0xFFEF4444)
        : const Color(0xFF0F172A);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: effectiveIconColor, size: 24),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
