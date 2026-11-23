import 'package:admin_mobile_app/core/models/role_model.dart';
import 'package:admin_mobile_app/core/utils/permission_helper.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_mobile_app/core/routes/app_routes.dart';
import '../../blocs/role/role_bloc.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/app_entity_action_menu.dart';
import 'add_role_page.dart';

class RolesPage extends StatelessWidget {
  const RolesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageRoles,
            style: GoogleFonts.montserrat(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: BlocConsumer<RoleBloc, RoleState>(
        listener: (context, state) {
          if (state is RoleOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is RoleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RoleLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RoleLoaded) {
            return state.roles.isEmpty
                ? Center(
                    child: Text(
                    AppLocalizations.of(context)!.noRolesFound,
                    style: GoogleFonts.montserrat(color: Colors.grey),
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.roles.length,
                    itemBuilder: (context, index) {
                      final role = state.roles[index];
                      return _buildRoleCard(context, role);
                    },
                  );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: PermissionHelper.hasPermission(context, 'add_roles')
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddRolePage()),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildRoleCard(BuildContext context, RoleModel role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          role.name,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (role.description != null && role.description!.isNotEmpty)
              Text(
                role.description!,
                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 4),
            Text(
              '${role.permissions.length} ${AppLocalizations.of(context)!.permissions}',
              style:
                  GoogleFonts.montserrat(fontSize: 12, color: Colors.blueGrey),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.roleDetails,
            arguments: role,
          );
        },
        trailing: AppEntityActionMenu(
          onView: () {
            Navigator.pushNamed(
              context,
              AppRoutes.roleDetails,
              arguments: role,
            );
          },
          onDelete: PermissionHelper.hasPermission(context, 'delete_roles')
              ? () => _showDeleteConfirmation(context, role)
              : null,
          deleteLabel: AppLocalizations.of(context)!.deleteRole,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, RoleModel role) {
    ConfirmationDialog.show(
      context: context,
      title: AppLocalizations.of(context)!.deleteRole,
      content: AppLocalizations.of(context)!.areYouSureYouWantToDeleteTheRole,
      confirmText: AppLocalizations.of(context)!.delete,
      cancelText: AppLocalizations.of(context)!.cancel,
      isDestructive: true,
      onConfirm: () {
        context.read<RoleBloc>().add(DeleteRole(role.id));
      },
    );
  }
}
