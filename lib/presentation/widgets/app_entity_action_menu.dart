import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppActionMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool isDestructive;

  const AppActionMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.isDestructive = false,
  });
}


class AppEntityActionMenu extends StatelessWidget {
  final VoidCallback? onView;
  final String? viewLabel;
  final VoidCallback? onEdit;
  final String? editLabel;
  final bool? isActive;
  final VoidCallback? onToggleStatus;
  final String? activeLabel;
  final String? inactiveLabel;
  final List<AppActionMenuItem>? customActions;
  final VoidCallback? onDelete;
  final String? deleteLabel;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final Widget? customTrigger;

  const AppEntityActionMenu({
    super.key,
    this.onView,
    this.viewLabel,
    this.onEdit,
    this.editLabel,
    this.isActive,
    this.onToggleStatus,
    this.activeLabel,
    this.inactiveLabel,
    this.customActions,
    this.onDelete,
    this.deleteLabel,
    this.iconColor,
    this.iconSize = 20,
    this.padding = EdgeInsets.zero,
    this.customTrigger,
  });

  @override
  Widget build(BuildContext context) {
    // If no actions are provided, hide trigger
    final hasActions = onView != null ||
        onEdit != null ||
        (isActive != null && onToggleStatus != null) ||
        (customActions != null && customActions!.isNotEmpty) ||
        onDelete != null;

    if (!hasActions) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      padding: padding,
      icon: customTrigger ??
          Icon(
            Icons.more_vert_rounded,
            color: iconColor ?? Colors.black54,
            size: iconSize,
          ),
      elevation: 4,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEBEBEB), width: 1),
      ),
      onSelected: (val) {
        if (val == 'view') {
          onView?.call();
        } else if (val == 'edit') {
          onEdit?.call();
        } else if (val == 'toggle_status') {
          onToggleStatus?.call();
        } else if (val == 'delete') {
          onDelete?.call();
        } else if (val.startsWith('custom_')) {
          final index = int.tryParse(val.replaceFirst('custom_', ''));
          if (index != null &&
              customActions != null &&
              index < customActions!.length) {
            customActions![index].onTap();
          }
        }
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = [];

        // 1. View Details
        if (onView != null) {
          items.add(
            PopupMenuItem<String>(
              value: 'view',
              height: 42,
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      size: 19, color: Color(0xFF2F92D0)),
                  const SizedBox(width: 10),
                  Text(
                    viewLabel ?? 'View Details',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 2. Edit
        if (onEdit != null) {
          items.add(
            PopupMenuItem<String>(
              value: 'edit',
              height: 42,
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 19, color: Color(0xFF222222)),
                  const SizedBox(width: 10),
                  Text(
                    editLabel ?? 'Edit',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 3. Status Toggle (Activate / Inactivate)
        if (isActive != null && onToggleStatus != null) {
          final isCurrentlyActive = isActive == true;
          final label = isCurrentlyActive
              ? (activeLabel ?? 'Inactivate')
              : (inactiveLabel ?? 'Activate');
          final icon = isCurrentlyActive
              ? Icons.pause_circle_outline_rounded
              : Icons.check_circle_outline_rounded;

          items.add(
            PopupMenuItem<String>(
              value: 'toggle_status',
              height: 42,
              child: Row(
                children: [
                  Icon(icon, size: 19, color: const Color(0xFF222222)),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 4. Custom Entity Actions
        if (customActions != null && customActions!.isNotEmpty) {
          for (int i = 0; i < customActions!.length; i++) {
            final action = customActions![i];
            items.add(
              PopupMenuItem<String>(
                value: 'custom_$i',
                height: 42,
                child: Row(
                  children: [
                    Icon(action.icon,
                        size: 19,
                        color: action.color ??
                            (action.isDestructive
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF222222))),
                    const SizedBox(width: 10),
                    Text(
                      action.label,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: action.color ??
                            (action.isDestructive
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF222222)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        // 5. Delete (Destructive action at the bottom)
        if (onDelete != null) {
          if (items.isNotEmpty) {
            items.add(
              const PopupMenuDivider(height: 8),
            );
          }
          items.add(
            PopupMenuItem<String>(
              value: 'delete',
              height: 42,
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded,
                      size: 19, color: Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  Text(
                    deleteLabel ?? 'Delete',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}
