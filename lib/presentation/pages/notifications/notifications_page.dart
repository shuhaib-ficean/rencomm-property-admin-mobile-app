import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:admin_mobile_app/l10n/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../blocs/notification/notification_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotifications());
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return 'Just now';
    try {
      final dateTime = DateTime.parse(createdAt.toString()).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, h:mm a').format(dateTime);
      }
    } catch (_) {
      return createdAt.toString();
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'payment':
        return Icons.payment;
      case 'maintenance':
      case 'repair':
        return Icons.build_rounded;
      case 'enquiry':
        return Icons.question_answer_rounded;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'payment':
        return Colors.green;
      case 'maintenance':
      case 'repair':
        return Colors.orange;
      case 'enquiry':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final String? id = notification['id'];
    final bool isRead = notification['isRead'] ?? false;
    final String? type = notification['type'];

    if (!isRead && id != null) {
      context.read<NotificationBloc>().add(MarkNotificationRead(id));
    }

    if (type == 'enquiry') {
      Navigator.pushNamed(context, AppRoutes.enquiries);
    } else if (type == 'maintenance' || type == 'repair') {
      Navigator.pushNamed(context, AppRoutes.repairs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.notifications,
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final hasUnread = state is NotificationLoaded &&
                  state.notifications.any((n) => n['isRead'] == false);
              if (!hasUnread) return const SizedBox.shrink();

              return TextButton.icon(
                onPressed: () {
                  context.read<NotificationBloc>().add(MarkAllNotificationsRead());
                },
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Read all'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationError) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(LoadNotifications());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.wifi_off_rounded,
                                size: 48, color: Colors.red),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Connection Issue',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context
                                  .read<NotificationBloc>()
                                  .add(LoadNotifications());
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
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
            );
          } else if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noNotification,
                      style: GoogleFonts.montserrat(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(LoadNotifications());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final raw = state.notifications[index];
                  final Map<String, dynamic> notification =
                      raw is Map<String, dynamic>
                          ? raw
                          : Map<String, dynamic>.from(raw as Map);

                  final String title = notification['title'] ?? 'Notification';
                  final String message = notification['message'] ?? '';
                  final String time = _formatTime(notification['createdAt'] ?? notification['time']);
                  final bool isRead = notification['isRead'] ?? false;
                  final String? type = notification['type'];
                  final icon = _getIconForType(type);
                  final color = _getColorForType(type);

                  return _buildNotificationCard(
                    title: title,
                    message: message,
                    time: time,
                    isRead: isRead,
                    icon: icon,
                    color: color,
                    onTap: () => _handleNotificationTap(notification),
                  );
                },
              ),
            );
          }
          return Center(
            child: Text(AppLocalizations.of(context)!.noNotification),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String time,
    required bool isRead,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isRead
            ? Border.all(color: Colors.grey[200]!)
            : Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                color: isRead ? Colors.black87 : Colors.blue[900],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.grey[800],
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
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
}
