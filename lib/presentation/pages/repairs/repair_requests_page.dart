import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/repair/repair_bloc.dart';
import '../../blocs/repair/repair_event.dart';
import '../../blocs/repair/repair_state.dart';
import '../../../../core/di/injection_container.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/repair_model.dart';
import 'add_repair_request_page.dart';
import '../../blocs/staff/staff_bloc.dart';
import '../../widgets/app_entity_action_menu.dart';
import '../../widgets/confirmation_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class RepairRequestsPage extends StatefulWidget {
  const RepairRequestsPage({super.key});

  @override
  State<RepairRequestsPage> createState() => _RepairRequestsPageState();
}

class _RepairRequestsPageState extends State<RepairRequestsPage>
    with SingleTickerProviderStateMixin {
  late RepairBloc _repairBloc;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _repairBloc = getIt<RepairBloc>()..add(const LoadRepairs());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isExtraService(RepairModel tkt) {
    final dept = tkt.department.toLowerCase().trim();
    final cat = tkt.category.toLowerCase().trim();

    const extraKeywords = [
      'cleaning',
      'clean',
      'housekeeping',
      'maid',
      'sanitiz',
      'laundry',
      'ironing',
      'wash',
      'dry clean',
      'linen',
      'pest',
      'fumigat',
      'insect',
      'rodent',
      'termite',
      'waste',
      'trash',
      'garbage',
      'gas refill',
      'gas delivery',
      'cooking gas',
      'cylinder',
      'water deliver',
      'bottled water',
      'car wash',
      'extra',
      'extras',
      'hospitality',
      'amenity service',
      'other service',
    ];

    for (final kw in extraKeywords) {
      if (dept.contains(kw) || cat.contains(kw)) {
        return true;
      }
    }

    if (dept == 'house cleaning' ||
        dept == 'laundry' ||
        dept == 'laundry services' ||
        dept == 'pest control' ||
        dept == 'cleaning' ||
        dept == 'extras' ||
        dept == 'other services' ||
        dept == 'others') {
      return true;
    }

    return false;
  }

  IconData _getServiceIcon(RepairModel tkt) {
    final dept = tkt.department.toLowerCase();
    final cat = tkt.category.toLowerCase();

    if (dept.contains('clean') || cat.contains('clean') || dept.contains('housekeeping')) {
      return Icons.cleaning_services_outlined;
    }
    if (dept.contains('laundry') || cat.contains('laundry') || cat.contains('ironing') || cat.contains('wash')) {
      return Icons.local_laundry_service_outlined;
    }
    if (dept.contains('pest') || cat.contains('pest') || cat.contains('insect') || cat.contains('rodent')) {
      return Icons.pest_control_outlined;
    }
    if (dept.contains('waste') || cat.contains('waste') || cat.contains('trash') || cat.contains('garbage')) {
      return Icons.delete_outline_rounded;
    }
    if (dept.contains('plumb') || cat.contains('plumb') || cat.contains('leak') || cat.contains('pipe')) {
      return Icons.plumbing_outlined;
    }
    if (dept.contains('elect') || cat.contains('elect') || cat.contains('wire') || cat.contains('power')) {
      return Icons.bolt_outlined;
    }
    if (dept.contains('hvac') || dept.contains('ac') || cat.contains('ac') || cat.contains('cooling')) {
      return Icons.ac_unit_outlined;
    }
    if (dept.contains('carpent') || cat.contains('door') || cat.contains('window') || cat.contains('lock')) {
      return Icons.door_front_door_outlined;
    }
    if (dept.contains('paint') || cat.contains('paint') || cat.contains('wall')) {
      return Icons.format_paint_outlined;
    }
    if (_isExtraService(tkt)) {
      return Icons.room_service_outlined;
    }
    return Icons.handyman_outlined;
  }

  List<RepairModel> _applyFilters(List<RepairModel> list) {
    return list.where((tkt) {
      if (_selectedStatusFilter != 'All' &&
          tkt.status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return tkt.ticket.toLowerCase().contains(q) ||
          (tkt.customerName?.toLowerCase().contains(q) ?? false) ||
          (tkt.propertyName?.toLowerCase().contains(q) ?? false) ||
          (tkt.roomNumber?.toLowerCase().contains(q) ?? false) ||
          tkt.department.toLowerCase().contains(q) ||
          tkt.category.toLowerCase().contains(q);
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'In Progress': return Colors.blue;
      default: return Colors.orange;
    }
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _formatImageUrl(String url) {
    if (url.startsWith('data:image') || url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final cleanBase = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$cleanBase${url.startsWith('/') ? '' : '/'}$url';
  }

  Widget _buildImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image')) {
      try {
        final base64Data = url.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: _formatImageUrl(url),
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: imageUrl.startsWith('data:image')
                  ? Image.memory(base64Decode(imageUrl.split(',').last))
                  : CachedNetworkImage(
                      imageUrl: _formatImageUrl(imageUrl),
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator(color: Colors.white)),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, color: Colors.white, size: 48),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTicketDetailsDialog(BuildContext context, RepairModel tkt) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tkt.ticket, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(tkt.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tkt.status, style: TextStyle(color: _getStatusColor(tkt.status), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${tkt.department} • ${tkt.category}', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('Property: ${tkt.propertyName ?? 'N/A'} (Unit: ${tkt.roomNumber ?? 'N/A'})', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  Text('Customer: ${tkt.customerName ?? 'N/A'} (${tkt.customerPhone ?? 'N/A'})', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  Text('Assigned Staff: ${tkt.staffName ?? 'Unassigned'}', style: TextStyle(fontSize: 13, color: tkt.staffName != null ? Colors.blue[700] : Colors.grey)),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Issue Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(tkt.description != null && tkt.description!.isNotEmpty ? tkt.description! : 'No description provided', style: const TextStyle(fontSize: 13)),
                  
                  // Tenant Initial Photos
                  if (tkt.images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Tenant Reported Photos (${tkt.images.length}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tkt.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final imgUrl = tkt.images[idx];
                          return GestureDetector(
                            onTap: () => _openFullScreenImage(context, imgUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildImage(imgUrl, width: 70, height: 70),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Staff Completion Proof Photos & Notes
                  if (tkt.completionImages.isNotEmpty || tkt.completionNotes != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Proof of Resolution (by ${tkt.staffName ?? 'Staff'}):',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (tkt.completionNotes != null && tkt.completionNotes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(tkt.completionNotes!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                          if (tkt.completionImages.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 70,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: tkt.completionImages.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, idx) {
                                  final imgUrl = tkt.completionImages[idx];
                                  return GestureDetector(
                                    onTap: () => _openFullScreenImage(context, imgUrl),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildImage(imgUrl, width: 70, height: 70),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAssignStaffDialog(String repairId) {
    String? selectedStaffId;
    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<StaffBloc, StaffState>(
          builder: (context, state) {
            if (state is StaffLoading) {
              return const AlertDialog(
                title: Text('Loading Staff...'),
                content: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is StaffLoaded) {
              final activeStaff = state.staff.where((s) => s.isActive).toList();
              return AlertDialog(
                title: Text('Assign Staff', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                content: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Staff Member', border: OutlineInputBorder()),
                  items: activeStaff.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) {
                    selectedStaffId = val;
                  },
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedStaffId != null) {
                        _repairBloc.add(AssignRepairStaff(repairId, selectedStaffId!));
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Assign'),
                  )
                ],
              );
            }
            return const AlertDialog(title: Text('Error loading staff'));
          },
        );
      },
    );
  }

  Widget _buildRepairCard(BuildContext context, RepairModel tkt) {
    final statusColor = _getStatusColor(tkt.status);
    final priorityColor = _getPriorityColor(tkt.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTicketDetailsDialog(context, tkt),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Ticket #, Priority Badge, Status Chip, Action Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(_getServiceIcon(tkt),
                        color: priorityColor, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tkt.ticket,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  tkt.priority.toUpperCase(),
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${tkt.department} • ${tkt.category}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        tkt.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    AppEntityActionMenu(
                      onView: () => _showTicketDetailsDialog(context, tkt),
                      viewLabel: 'View Details & Proof',
                      customActions: [
                        AppActionMenuItem(
                          label: 'Assign Staff',
                          icon: Icons.person_add_outlined,
                          color: Colors.blue[700],
                          onTap: () => _showAssignStaffDialog(tkt.id),
                        ),
                        if (tkt.status != 'Resolved')
                          AppActionMenuItem(
                            label: 'Mark Resolved',
                            icon: Icons.check_circle_outline,
                            color: Colors.green[700],
                            onTap: () => _repairBloc
                                .add(UpdateRepairStatus(tkt.id, 'Resolved')),
                          ),
                        if (tkt.status != 'Rejected')
                          AppActionMenuItem(
                            label: 'Reject Ticket',
                            icon: Icons.cancel_outlined,
                            color: Colors.red[700],
                            isDestructive: true,
                            onTap: () {
                              ConfirmationDialog.show(
                                context: context,
                                title: 'Reject ${_isExtraService(tkt) ? 'Service Request' : 'Repair Request'}',
                                content:
                                    'Are you sure you want to mark ticket "${tkt.ticket}" as rejected?',
                                confirmText: 'Reject',
                                cancelText: 'Cancel',
                                isDestructive: true,
                                onConfirm: () => _repairBloc
                                    .add(UpdateRepairStatus(tkt.id, 'Rejected')),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Info Rows: Property & Room, Customer / Tenant, Staff
                Row(
                  children: [
                    const Icon(Icons.home_work_outlined,
                        size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${tkt.propertyName ?? 'N/A'} • Unit ${tkt.roomNumber ?? 'N/A'}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          color: const Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (tkt.customerName != null &&
                    tkt.customerName!.trim().isNotEmpty &&
                    tkt.customerName != 'Tenant') ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${tkt.customerName!} (${tkt.customerPhone ?? 'No Phone'})',
                          style: GoogleFonts.montserrat(
                            fontSize: 12.5,
                            color: const Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tkt.customerPhone != null &&
                          tkt.customerPhone!.trim().isNotEmpty &&
                          tkt.customerPhone != 'N/A')
                        InkWell(
                          onTap: () => launchUrl(
                              Uri.parse('tel:${tkt.customerPhone!.trim()}')),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_rounded,
                                    size: 13, color: Colors.green),
                                const SizedBox(width: 3),
                                Text(
                                  'Call',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.engineering_outlined,
                      size: 14,
                      color: tkt.staffName != null
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tkt.staffName != null
                            ? 'Assigned: ${tkt.staffName}'
                            : 'Unassigned Staff',
                        style: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          color: tkt.staffName != null
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFD97706),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Description preview if available
                if (tkt.description != null &&
                    tkt.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tkt.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],

                // Thumbnail Strip if images exist
                if (tkt.images.isNotEmpty ||
                    tkt.completionImages.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...tkt.images.map(
                          (img) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => _openFullScreenImage(context, img),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: _buildImage(img, width: 48, height: 48),
                              ),
                            ),
                          ),
                        ),
                        ...tkt.completionImages.map(
                          (img) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => _openFullScreenImage(context, img),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: _buildImage(img,
                                        width: 48, height: 48),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check,
                                          size: 10, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context, {
    required List<RepairModel> items,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required String ticketsLabel,
  }) {
    return Column(
      children: [
        // Tickets Count Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticketsLabel,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
                onPressed: () => _repairBloc.add(const LoadRepairs()),
              ),
            ],
          ),
        ),

        // Cards List or Empty State
        Expanded(
          child: items.isEmpty
              ? RefreshIndicator(
                  onRefresh: () async {
                    _repairBloc.add(const LoadRepairs());
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.42,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                emptyIcon,
                                size: 56,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                emptyTitle,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                emptySubtitle,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _repairBloc.add(const LoadRepairs());
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildRepairCard(context, items[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _repairBloc,
      child: BlocConsumer<RepairBloc, RepairState>(
        listener: (context, state) {
          if (state is RepairLoaded && state.operationSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.operationSuccess!),
                backgroundColor: Colors.green));
          }
          if (state is RepairLoaded && state.operationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.operationError!),
                backgroundColor: Colors.red));
          }
          if (state is RepairError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          final allRepairs = state is RepairLoaded ? state.repairs : <RepairModel>[];
          final repairTickets = allRepairs.where((t) => !_isExtraService(t)).toList();
          final extraTickets = allRepairs.where((t) => _isExtraService(t)).toList();

          final filteredRepairs = _applyFilters(repairTickets);
          final filteredExtras = _applyFilters(extraTickets);

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: Text(
                'Services',
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF2F92D0),
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: const Color(0xFF2F92D0),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.handyman_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text('Repairs (${repairTickets.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.room_service_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text('Extras (${extraTickets.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: state is RepairLoading || state is RepairInitial
                ? const Center(child: CircularProgressIndicator())
                : state is RepairError
                    ? Center(child: Text('Error loading services: ${state.message}'))
                    : Column(
                        children: [
                          // Top Search and Filter Section
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Column(
                              children: [
                                // Search Bar
                                TextField(
                                  controller: _searchController,
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val.trim();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: _tabController.index == 0
                                        ? 'Search repairs by ticket, dept, customer...'
                                        : 'Search extras by ticket, service, tenant...',
                                    hintStyle: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: Colors.grey[400],
                                    ),
                                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2F92D0)),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, color: Colors.grey),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchQuery = '';
                                              });
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2F92D0)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Status Filter Chips
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      'All',
                                      'Pending',
                                      'In Progress',
                                      'Resolved',
                                      'Rejected',
                                    ].map((status) {
                                      final isSelected = _selectedStatusFilter == status;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(status),
                                          labelStyle: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF475569),
                                          ),
                                          selected: isSelected,
                                          selectedColor: const Color(0xFF2F92D0),
                                          backgroundColor: const Color(0xFFF1F5F9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? const Color(0xFF2F92D0)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          onSelected: (sel) {
                                            if (sel) {
                                              setState(() {
                                                _selectedStatusFilter = status;
                                              });
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // TabBarView for Repairs and Extras
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildTabContent(
                                  context,
                                  items: filteredRepairs,
                                  emptyIcon: Icons.handyman_outlined,
                                  emptyTitle: 'No repair requests found',
                                  emptySubtitle:
                                      'Plumbing, electrical, AC, door/window and other repair tickets will appear here',
                                  ticketsLabel: 'Repair Tickets (${filteredRepairs.length})',
                                ),
                                _buildTabContent(
                                  context,
                                  items: filteredExtras,
                                  emptyIcon: Icons.room_service_outlined,
                                  emptyTitle: 'No extra service requests found',
                                  emptySubtitle:
                                      'House cleaning, laundry, pest control and other extra services will appear here',
                                  ticketsLabel: 'Extra Services (${filteredExtras.length})',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final currentServiceType = _tabController.index == 1 ? 'Extras' : 'Repairs';
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: _repairBloc,
                      child: AddRepairRequestPage(initialServiceType: currentServiceType),
                    ),
                  ),
                );
                if (context.mounted) {
                  _repairBloc.add(const LoadRepairs());
                }
              },
              backgroundColor: const Color(0xFF2F92D0),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
