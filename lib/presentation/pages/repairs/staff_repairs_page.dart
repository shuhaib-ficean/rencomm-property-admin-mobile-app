import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/models/repair_model.dart';
import '../../blocs/repair/repair_bloc.dart';
import '../../blocs/repair/repair_event.dart';
import '../../blocs/repair/repair_state.dart';
import 'staff_repair_details_page.dart';

class StaffRepairsPage extends StatefulWidget {
  const StaffRepairsPage({super.key});

  @override
  State<StaffRepairsPage> createState() => _StaffRepairsPageState();
}

class _StaffRepairsPageState extends State<StaffRepairsPage> {
  late RepairBloc _repairBloc;
  String _selectedFilter = 'all'; // 'all', 'in progress', 'pending', 'resolved'

  @override
  void initState() {
    super.initState();
    _repairBloc = getIt<RepairBloc>()..add(const LoadRepairs());
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF10B981);
      case 'in progress':
        return const Color(0xFF2563EB);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  List<RepairModel> _filterRepairs(List<RepairModel> repairs) {
    if (_selectedFilter == 'all') return repairs;
    return repairs
        .where((r) => r.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _repairBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.build_circle_rounded, color: Color(0xFF2F92D0), size: 26),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Tasks',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Maintenance & Repairs',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
              onPressed: () => _repairBloc.add(const LoadRepairs()),
              tooltip: 'Refresh tasks',
            ),
          ],
        ),
        body: BlocConsumer<RepairBloc, RepairState>(
          listener: (context, state) {
            if (state is RepairLoaded && state.operationSuccess != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.operationSuccess!),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is RepairLoading || state is RepairInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RepairError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading tasks', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _repairBloc.add(const LoadRepairs()),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allRepairs = (state as RepairLoaded).repairs;
            final filteredRepairs = _filterRepairs(allRepairs);

            return RefreshIndicator(
              onRefresh: () async {
                _repairBloc.add(const LoadRepairs());
              },
              child: Column(
                children: [
                  // Filter Chips Bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All (${allRepairs.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'in progress',
                            'In Progress (${allRepairs.where((r) => r.status.toLowerCase() == 'in progress').length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'pending',
                            'Pending (${allRepairs.where((r) => r.status.toLowerCase() == 'pending').length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'resolved',
                            'Resolved (${allRepairs.where((r) => r.status.toLowerCase() == 'resolved').length})',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Task Cards List
                  Expanded(
                    child: filteredRepairs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedFilter == 'all'
                                        ? 'No repair tasks assigned'
                                        : 'No $_selectedFilter tasks',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'When a property admin assigns a repair ticket to you, it will appear here.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredRepairs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final repair = filteredRepairs[index];
                              return _buildTaskCard(context, repair);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = filterKey);
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, RepairModel repair) {
    final statusColor = _getStatusColor(repair.status);
    final priorityColor = _getPriorityColor(repair.priority);

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: _repairBloc,
              child: StaffRepairDetailsPage(repair: repair),
            ),
          ),
        );
        if (result == true) {
          _repairBloc.add(const LoadRepairs());
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Ticket + Priority & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      repair.ticket,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        repair.priority,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    repair.status,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Issue Title / Category
            Text(
              repair.category,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),

            // Property & Unit
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${repair.propertyName ?? 'Property'} • ${repair.roomNumber != null ? 'Unit ${repair.roomNumber}' : 'General Area'}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description preview
            if (repair.description != null && repair.description!.isNotEmpty)
              Text(
                repair.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Bottom: Tenant info + Action CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tenant contact
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFFF1F5F9),
                      child: Icon(Icons.person, size: 16, color: Color(0xFF475569)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repair.customerName ?? 'Tenant',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        if (repair.customerPhone != null && repair.customerPhone != 'N/A')
                          Text(
                            repair.customerPhone!,
                            style: GoogleFonts.montserrat(fontSize: 11, color: const Color(0xFF64748B)),
                          ),
                      ],
                    ),
                    if (repair.customerPhone != null &&
                        repair.customerPhone!.trim().isNotEmpty &&
                        repair.customerPhone != 'N/A')
                      IconButton(
                        icon: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 18),
                        onPressed: () => _makePhoneCall(repair.customerPhone!),
                        tooltip: 'Call Tenant',
                        padding: const EdgeInsets.only(left: 8),
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),

                // Action Pill
                if (repair.status.toLowerCase() == 'pending')
                  ElevatedButton(
                    onPressed: () {
                      _repairBloc.add(UpdateRepairStatus(repair.id, 'In Progress'));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text('Start Work', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                else if (repair.status.toLowerCase() == 'in progress')
                  ElevatedButton.icon(
                    onPressed: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: _repairBloc,
                            child: StaffRepairDetailsPage(repair: repair),
                          ),
                        ),
                      );
                      if (res == true) _repairBloc.add(const LoadRepairs());
                    },
                    icon: const Icon(Icons.camera_alt, size: 14),
                    label: Text('Upload Proof', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
