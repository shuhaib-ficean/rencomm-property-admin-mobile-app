import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/tenant/tenant_bloc.dart';
import '../../../core/models/tenant_model.dart';
import '../../../core/routes/app_routes.dart';

class RenewalRequestsPage extends StatefulWidget {
  const RenewalRequestsPage({super.key});

  @override
  State<RenewalRequestsPage> createState() => _RenewalRequestsPageState();
}

class _RenewalRequestsPageState extends State<RenewalRequestsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'Pending', 'Completed'
  final Set<String> _manuallyCompletedTenantIds = {};
  final Set<String> _manuallyPendingTenantIds = {};

  @override
  void initState() {
    super.initState();
    context.read<TenantBloc>().add(const LoadTenants(isRefresh: true));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getRenewals(List<TenantModel> tenants) {
    return tenants
        .where((t) => t.assignedRoom != null || t.assignedRoomId != null)
        .map((t) {
      final activeLease = t.leaseList?.isNotEmpty == true
          ? t.leaseList!.firstWhere((l) => l.status == 'active',
              orElse: () => t.leaseList!.first)
          : null;

      final endDate = t.contractEndDate ?? activeLease?.endDate;
      final rent = activeLease?.rentAmount ?? t.rentAmount;
      final deposit = activeLease?.securityDeposit ?? t.securityDeposit;

      bool isCompleted = false;
      if (_manuallyCompletedTenantIds.contains(t.id)) {
        isCompleted = true;
      } else if (_manuallyPendingTenantIds.contains(t.id)) {
        isCompleted = false;
      } else {
        if (endDate != null) {
          // If contract has expired or expires within 30 days -> Pending
          // If contract is active and safe (> 30 days left) -> Completed
          final daysLeft = endDate.difference(DateTime.now()).inDays;
          isCompleted = daysLeft > 30;
        } else {
          // Recurring month-to-month contracts are ongoing/up-to-date
          isCompleted = true;
        }
      }

      return {
        'id': t.id.length >= 8
            ? t.id.substring(0, 8).toUpperCase()
            : t.id.toUpperCase(),
        'tenantId': t.id,
        'tenant': t.name,
        'phone': t.phone,
        'email': t.email ?? '',
        'qatarId': t.qatarId ?? '',
        'property': t.property?.name ?? 'N/A',
        'propertyId': t.property?.id ?? t.assignedPropertyId,
        'room': t.assignedRoom?.number ?? 'N/A',
        'roomId': t.assignedRoom?.id ?? t.assignedRoomId,
        'floor': t.assignedRoom?.floorName ?? '',
        'current_end': endDate != null
            ? DateFormat('MMM dd, yyyy').format(endDate)
            : 'Recurring',
        'requested_start': endDate != null
            ? DateFormat('MMM dd, yyyy').format(endDate.add(const Duration(days: 1)))
            : 'Immediate',
        'rent': rent,
        'deposit': deposit,
        'status': isCompleted ? 'Completed' : 'Pending',
        'rawTenant': t,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _filterRenewals(List<Map<String, dynamic>> allRenewals) {
    return allRenewals.where((item) {
      // Status filter
      if (_selectedStatusFilter != 'All' &&
          item['status'].toString().toLowerCase() !=
              _selectedStatusFilter.toLowerCase()) {
        return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = item['tenant'].toString().toLowerCase();
        final phone = item['phone'].toString().toLowerCase();
        final property = item['property'].toString().toLowerCase();
        final room = item['room'].toString().toLowerCase();
        final qid = item['qatarId'].toString().toLowerCase();

        if (!name.contains(query) &&
            !phone.contains(query) &&
            !property.contains(query) &&
            !room.contains(query) &&
            !qid.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber.trim());
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (_) {}
  }

  void _openDetailBottomSheet(Map<String, dynamic> renewal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(
                    renewal['tenant'].toString().isNotEmpty
                        ? renewal['tenant'].toString()[0].toUpperCase()
                        : 'T',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        renewal['tenant'],
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${renewal['id']}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(renewal['status'])
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    renewal['status'],
                    style: GoogleFonts.montserrat(
                      color: _getStatusColor(renewal['status']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildDetailTile(Icons.phone_outlined, 'Phone', renewal['phone'],
                action: IconButton(
                  icon: const Icon(Icons.call, color: Colors.green, size: 20),
                  onPressed: () => _makePhoneCall(renewal['phone']),
                )),
            if (renewal['qatarId'].toString().isNotEmpty)
              _buildDetailTile(
                  Icons.badge_outlined, 'Qatar ID', renewal['qatarId']),
            _buildDetailTile(Icons.apartment_rounded, 'Property & Room',
                '${renewal['property']} • Room ${renewal['room']}${renewal['floor'].toString().isNotEmpty ? ' (Floor ${renewal['floor']})' : ''}'),
            _buildDetailTile(Icons.calendar_month_outlined, 'Current End Date',
                renewal['current_end']),
            _buildDetailTile(Icons.update_rounded, 'Next Lease Cycle',
                renewal['requested_start']),
            if (renewal['rent'] != null && renewal['rent'] > 0)
              _buildDetailTile(Icons.payments_outlined, 'Rent Amount',
                  'QR ${renewal['rent']}'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.createLease,
                        arguments: {
                          'tenantId': renewal['tenantId'],
                          'propertyId': renewal['propertyId'],
                          'roomId': renewal['roomId'],
                          'rentAmount': renewal['rent'],
                          'securityDeposit': renewal['deposit'],
                        },
                      ).then((_) {
                        if (!mounted) return;
                        setState(() {
                          _manuallyCompletedTenantIds.add(renewal['tenantId']);
                          _manuallyPendingTenantIds.remove(renewal['tenantId']);
                        });
                        context
                            .read<TenantBloc>()
                            .add(const LoadTenants(isRefresh: true));
                      });
                    },
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Create New Lease'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    final tenantId = renewal['tenantId'] as String;
                    final bool isCurrentlyCompleted =
                        renewal['status'] == 'Completed';
                    setState(() {
                      if (isCurrentlyCompleted) {
                        _manuallyPendingTenantIds.add(tenantId);
                        _manuallyCompletedTenantIds.remove(tenantId);
                      } else {
                        _manuallyCompletedTenantIds.add(tenantId);
                        _manuallyPendingTenantIds.remove(tenantId);
                      }
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isCurrentlyCompleted
                            ? 'Renewal marked as Pending'
                            : 'Renewal marked as Completed'),
                        backgroundColor: isCurrentlyCompleted
                            ? Colors.orange
                            : Colors.green,
                      ),
                    );
                  },
                  icon: Icon(
                    renewal['status'] == 'Completed'
                        ? Icons.replay_rounded
                        : Icons.check_circle_outline,
                    size: 16,
                  ),
                  label: Text(renewal['status'] == 'Completed'
                      ? 'Mark Pending'
                      : 'Mark Completed'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: renewal['status'] == 'Completed'
                        ? Colors.orange[800]
                        : Colors.green[700],
                    side: BorderSide(
                      color: renewal['status'] == 'Completed'
                          ? Colors.orange[300]!
                          : Colors.green[300]!,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(
                  context,
                  AppRoutes.personDetails,
                  arguments: renewal['rawTenant'],
                );
              },
              icon: const Icon(Icons.person_outline_rounded, size: 18),
              label: const Text('View Tenant Profile & Active Lease'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[700],
                side: BorderSide(color: Colors.blue[300]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value,
      {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Renewal Requests',
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<TenantBloc>().add(const LoadTenants(isRefresh: true));
            },
          ),
        ],
      ),
      body: BlocBuilder<TenantBloc, TenantState>(
        builder: (context, state) {
          if (state is TenantLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TenantError && !state.isOperationError) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<TenantBloc>().add(const LoadTenants(isRefresh: true));
              },
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
                        'Unable to Load Renewals',
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
            );
          } else if (state is TenantLoaded) {
            final allRenewals = _getRenewals(state.tenants);
            final filteredRenewals = _filterRenewals(allRenewals);

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<TenantBloc>()
                    .add(const LoadTenants(isRefresh: true));
              },
              child: Column(
                children: [
                  // Search & Filter header
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search bar
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _searchQuery = val.trim());
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by tenant, property, or room…',
                            hintStyle: GoogleFonts.montserrat(
                                fontSize: 13, color: Colors.grey[400]),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.blue),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Filter Chips
                        Row(
                          children: [
                            _buildFilterChip('All', allRenewals.length),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'Pending',
                              allRenewals
                                  .where((r) => r['status'] == 'Pending')
                                  .length,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'Completed',
                              allRenewals
                                  .where((r) => r['status'] == 'Completed')
                                  .length,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Renewal list
                  Expanded(
                    child: filteredRenewals.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.autorenew_rounded,
                                        size: 38, color: Colors.blue[400]),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty ||
                                            _selectedStatusFilter != 'All'
                                        ? 'No matching renewal requests'
                                        : 'No renewal requests found',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Try a different search keyword'
                                        : 'All tenant leases are currently up to date.',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredRenewals.length,
                            itemBuilder: (context, index) {
                              final rnw = filteredRenewals[index];
                              return _buildRenewalCard(rnw);
                            },
                          ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('No data available'));
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedStatusFilter == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedStatusFilter = label);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenewalCard(Map<String, dynamic> rnw) {
    final statusColor = _getStatusColor(rnw['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetailBottomSheet(rnw),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Name, Phone, and Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    child: Text(
                      rnw['tenant'].toString().isNotEmpty
                          ? rnw['tenant'].toString()[0].toUpperCase()
                          : 'T',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rnw['tenant'],
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 13, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              rnw['phone'],
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rnw['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Property and Room badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.apartment_rounded,
                        size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${rnw['property']} • Room ${rnw['room']}',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Dates info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current End Date',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rnw['current_end'],
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Cycle',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rnw['requested_start'],
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openDetailBottomSheet(rnw),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[800],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.createLease,
                          arguments: {
                            'tenantId': rnw['tenantId'],
                            'propertyId': rnw['propertyId'],
                            'roomId': rnw['roomId'],
                            'rentAmount': rnw['rent'],
                            'securityDeposit': rnw['deposit'],
                          },
                        ).then((_) {
                          if (!mounted) return;
                          setState(() {
                            _manuallyCompletedTenantIds.add(rnw['tenantId']);
                            _manuallyPendingTenantIds.remove(rnw['tenantId']);
                          });
                          context
                              .read<TenantBloc>()
                              .add(const LoadTenants(isRefresh: true));
                        });
                      },
                      icon: Icon(
                        rnw['status'] == 'Completed'
                            ? Icons.check_circle_outline
                            : Icons.add_task_rounded,
                        size: 16,
                      ),
                      label: Text(rnw['status'] == 'Completed'
                          ? 'Renew Again'
                          : 'Renew Lease'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rnw['status'] == 'Completed'
                            ? Colors.teal
                            : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
