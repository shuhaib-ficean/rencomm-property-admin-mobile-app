import 'package:admin_mobile_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/analytics/analytics_bloc.dart';
import '../../blocs/property/property_bloc.dart';
import 'widgets/dashboard_charts.dart';
import '../../../core/utils/excel_export_service.dart';
import 'package:intl/intl.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/models/analytics_model.dart';
import '../../blocs/notification/notification_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dashboard,
            style: GoogleFonts.montserrat(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<AnalyticsBloc, AnalyticsState>(
            builder: (context, state) {
              if (state is AnalyticsLoaded) {
                return IconButton(
                  icon: const Icon(Icons.download_outlined,
                      color: Colors.black54),
                  tooltip: 'Export as Excel',
                  onPressed: () async {
                    try {
                      // Overview Data
                      final headers = [
                        'Metric',
                        'Value',
                        '',
                        'Metric',
                        'Value'
                      ];
                      final data = <List<dynamic>>[];

                      // Row 1
                      data.add([
                        'Total Revenue',
                        (NumberFormat.currency(symbol: 'QR ')
                            .format(state.summary.totalReceived)),
                        '',
                        // 'Total Expected',
                        // (NumberFormat.currency(symbol: 'QR ')
                        //     .format(state.summary.totalExpected))
                      ]);
                      // Row 2
                      data.add([
                        'Total Pending',
                        (NumberFormat.currency(symbol: 'QR ')
                            .format(state.summary.totalPending)),
                        '',
                        'Total Tenants',
                        state.summary.totalTenants
                      ]);
                      // Row 3 (New)
                      data.add([
                        'Vacant Rooms',
                        state.summary.totalVacantRooms,
                        '',
                        '',
                        ''
                      ]);
                      data.add(['', '', '', '', '']); // Empty row

                      // Staff Collections
                      data.add(['Staff Collections', '', '', '', '']);
                      data.add(['Staff Name', 'Amount Collected', '', '', '']);
                      for (var sc in state.staffCollections) {
                        data.add([sc.staffName, sc.totalAmount, '', '', '']);
                      }
                      data.add(['', '', '', '', '']); // Empty row

                      // Property Analytics
                      data.add(['Property Analytics', '', '', '', '']);
                      data.add([
                        'Property Name',
                        'Revenue',
                        'Occupied Units',
                        'Total Units',
                        'Occupancy Rate'
                      ]);
                      for (var pa in state.propertyAnalytics) {
                        data.add([
                          pa.name,
                          pa.revenue,
                          pa.occupiedUnits,
                          pa.totalUnits,
                          '${pa.occupancyRate.toStringAsFixed(1)}%'
                        ]);
                      }

                      await ExcelExportService.exportAndOpenFile(
                        fileName:
                            'Dashboard_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
                        sheetName: 'Dashboard',
                        headers: headers,
                        data: data,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to export Excel: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is NotificationLoaded) {
                unreadCount = state.notifications
                    .where((n) => n['isRead'] == false)
                    .length;
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.notifications);
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocListener<AnalyticsBloc, AnalyticsState>(
        listener: (context, state) {
          if (state is AnalyticsLoaded) {
            if (state.operationError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.operationError!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else if (state is AnalyticsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<AnalyticsBloc>().add(const LoadAnalyticsOverview());
            context.read<PropertyBloc>().add(const LoadProperties());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.overview,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          if (context.mounted) {
                            context.read<AnalyticsBloc>().add(
                                  LoadAnalyticsOverview(
                                    startDate: picked.start,
                                    endDate: picked.end,
                                  ),
                                );
                          }
                        }
                      },
                      icon: const Icon(Icons.date_range, color: Color(0xFF2F92D0)),
                      label: Text(
                        'Filter Dates',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2F92D0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BlocBuilder<AnalyticsBloc, AnalyticsState>(
                  builder: (context, state) {
                    if (state is AnalyticsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is AnalyticsLoaded) {
                      final summary = state.summary;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopKpiCards(context, summary),
                          const SizedBox(height: 24),
                          _buildLeaseSection(context, summary),
                          const SizedBox(height: 20),
                          _buildMaintenanceSection(context, summary),
                          const SizedBox(height: 24),
                          _buildQuickActions(context),
                          const SizedBox(height: 24),
                          DashboardCharts(
                            staffCollections: state.staffCollections,
                            propertyAnalytics: state.propertyAnalytics,
                          ),
                        ],
                      );
                    } else if (state is AnalyticsError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.error}: ${state.message}',
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<AnalyticsBloc>()
                                    .add(const LoadAnalyticsOverview());
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopKpiCards(BuildContext context, TenantSummaryModel summary) {
    return BlocBuilder<PropertyBloc, PropertyState>(
      builder: (context, propertyState) {
        String totalProperties = '...';
        int vacantPropertiesCount = 0;
        if (propertyState is PropertyLoaded) {
          totalProperties = propertyState.properties.length.toString();
          vacantPropertiesCount = propertyState.properties
              .where((p) => p.hasVacantRooms)
              .length;
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Properties',
                value: totalProperties,
                icon: Icons.apartment_rounded,
                iconColor: const Color(0xFF2F92D0),
                trend: 'Manage Properties',
                onTap: () => Navigator.pushNamed(context, AppRoutes.properties),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Vacant Properties',
                value: '$vacantPropertiesCount',
                icon: Icons.home_work_outlined,
                iconColor: Colors.amber.shade800,
                trend: '${summary.totalVacantRooms} Vacant Units',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.properties);
                  context.read<PropertyBloc>().add(
                        const LoadProperties(vacantOnly: true),
                      );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String trend,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 26),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2F92D0)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF717171),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFEBEBEB), width: 0.8),
              ),
              child: Text(
                trend,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionBtn(context, Icons.add_home_work_outlined, 'Add Property', AppRoutes.addProperty),
            _buildActionBtn(context, Icons.person_add_alt_1_outlined, 'Add Tenant', AppRoutes.addPerson),
            _buildActionBtn(context, Icons.question_answer_outlined, 'Enquiries', AppRoutes.enquiries),
            _buildActionBtn(context, Icons.corporate_fare_outlined, 'Departments', AppRoutes.departments),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, IconData icon, String label, String? route) {
    return InkWell(
      onTap: () {
        if (route != null) {
          Navigator.pushNamed(context, route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF2F92D0), size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaseSection(BuildContext context, TenantSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: Color(0xFF2F92D0), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Lease Management',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF222222),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.renewals),
                child: Row(
                  children: [
                    Text(
                      'Renewals',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2F92D0),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFF2F92D0)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Uncolored clean neutral metrics strip (No pastel noise)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Contracts',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: const Color(0xFF717171),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.totalTenants} Tenants Under Lease',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: const Color(0xFFEBEBEB),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Occupied Units',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: const Color(0xFF717171),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.totalOccupiedRooms} / ${summary.totalRooms} Units',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.createLease),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create New Lease'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F92D0),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF2F92D0).withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.renewals),
                  icon: const Icon(Icons.autorenew_rounded, size: 18),
                  label: const Text('Renewals'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2F92D0),
                    side: const BorderSide(color: Color(0xFF2F92D0), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection(BuildContext context, TenantSummaryModel summary) {
    final hasPending = summary.totalPendingRepairs > 0;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.home_repair_service_outlined,
                    color: hasPending ? const Color(0xFFDC2626) : const Color(0xFF2F92D0),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Services',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF222222),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.services),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2F92D0),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFF2F92D0)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Uncolored clean neutral status strip (No pastel noise)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: hasPending ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasPending
                                ? '${summary.totalPendingRepairs} Pending Service Requests'
                                : 'All Services Resolved',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF222222),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasPending
                            ? 'Requires staff or technician dispatch across properties'
                            : 'No pending repairs or extra services reported by tenants',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: const Color(0xFF717171),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.services),
              icon: const Icon(Icons.home_repair_service_outlined, size: 18),
              label: Text(
                hasPending ? 'Manage Service Requests' : 'View Services History',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F92D0),
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: const Color(0xFF2F92D0).withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
