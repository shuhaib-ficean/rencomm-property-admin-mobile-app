import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/property_model.dart';
import '../../../core/models/tenant_model.dart';
import '../../../core/routes/app_routes.dart';
import '../../blocs/property/property_bloc.dart';
import '../../widgets/app_entity_action_menu.dart';
import '../../widgets/confirmation_dialog.dart';
import 'edit_property_page.dart';
import 'manage_floors_rooms_page.dart';
import '../people/add_person_page.dart';

class PropertyDetailsPage extends StatefulWidget {
  const PropertyDetailsPage({super.key});

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String? rawPhone) async {
    final phone = rawPhone?.replaceAll(RegExp(r'\s+'), '');
    if (phone == null || phone.isEmpty) {
      _showToast('Contact number is not available.');
      return;
    }
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showToast('Could not open phone dialer: $e');
    }
  }

  Future<void> _openWhatsApp(String? rawPhone, String entityName) async {
    if (rawPhone == null || rawPhone.isEmpty) {
      _showToast('WhatsApp number is not available.');
      return;
    }
    var cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.startsWith('+')) {
      cleanPhone = cleanPhone.substring(1);
    }
    final message = Uri.encodeComponent('Hello, contacting regarding $entityName');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showToast('Could not open WhatsApp.');
      }
    } catch (e) {
      _showToast('Error opening WhatsApp: $e');
    }
  }

  Future<void> _openMaps(String? address) async {
    if (address == null || address.isEmpty) {
      _showToast('No location address specified.');
      return;
    }
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showToast('Could not open Maps.');
      }
    } catch (e) {
      _showToast('Error opening Maps: $e');
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast('$label copied to clipboard');
  }

  void _openFullScreenGallery(List<String> images, int initialIndex, String title) {
    if (images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyArg =
        ModalRoute.of(context)!.settings.arguments as PropertyModel?;

    if (propertyArg == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Invalid arguments')),
      );
    }

    return BlocConsumer<PropertyBloc, PropertyState>(
      listener: (context, state) {
        if (state is PropertyOperationSuccess) {
          _showToast(state.message);
          if (state.message.toLowerCase().contains('delete')) {
            Navigator.pop(context);
          }
        } else if (state is PropertyLoaded) {
          if (state.operationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.operationError!),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.operationSuccess != null) {
            _showToast(state.operationSuccess!);
          }
        } else if (state is PropertyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        PropertyModel currentProp = propertyArg;
        if (state is PropertyLoaded) {
          currentProp = state.properties.firstWhere(
            (p) => p.id == propertyArg.id,
            orElse: () => propertyArg,
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              currentProp.name,
              style: GoogleFonts.montserrat(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              AppEntityActionMenu(
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditPropertyPage(property: currentProp),
                    ),
                  );
                },
                editLabel: 'Edit Property',
                isActive: currentProp.status.toLowerCase() == 'active',
                onToggleStatus: () {
                  if (currentProp.status.toLowerCase() == 'active') {
                    if (currentProp.hasActiveTenants) {
                      _showCannotInactivateDialog(context);
                    } else {
                      _showConfirmation(
                        context,
                        currentProp,
                        'Inactivate',
                        'Are you sure you want to inactivate this property?',
                      );
                    }
                  } else {
                    _showConfirmation(
                      context,
                      currentProp,
                      'Activate',
                      'Are you sure you want to activate this property?',
                    );
                  }
                },
                customActions: [
                  AppActionMenuItem(
                    label: 'Manage Floors & Units',
                    icon: Icons.dashboard_customize_outlined,
                    color: Colors.blue[700],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ManageFloorsRoomsPage(property: currentProp),
                        ),
                      );
                    },
                  ),
                  AppActionMenuItem(
                    label: 'Manage Amenities',
                    icon: Icons.spa_outlined,
                    color: Colors.teal[700],
                    onTap: () => _showPropertyAmenitiesDialog(context, currentProp),
                  ),
                ],
                onDelete: () => _showDeleteConfirmation(context, currentProp),
                deleteLabel: 'Delete Property',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGalleryHeader(currentProp),
                const SizedBox(height: 16),
                _buildBasicInfo(currentProp),
                const SizedBox(height: 16),
                _buildKPIOverview(currentProp),
                const SizedBox(height: 16),
                _buildAmenitiesSection(context, currentProp),
                const SizedBox(height: 16),
                _buildStructureInfo(context, currentProp),
                const SizedBox(height: 16),
                _buildEnquiriesInfo(currentProp),
                const SizedBox(height: 16),
                _buildExpensesInfo(currentProp),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, PropertyModel property) {
    ConfirmationDialog.show(
      context: context,
      title: 'Delete Property',
      content: 'Are you sure you want to permanently delete this property?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
      onConfirm: () =>
          context.read<PropertyBloc>().add(DeleteProperty(property.id)),
    );
  }

  void _showCannotInactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cannot Inactivate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Cannot inactivate this property because there are active tenants occupying units. Please vacate or reassign all tenants before setting the property to inactive.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showConfirmation(
      BuildContext context, PropertyModel prop, String title, String content) {
    ConfirmationDialog.show(
      context: context,
      title: title,
      content: content,
      confirmText: 'Confirm',
      cancelText: 'Cancel',
      onConfirm: () {
        final newStatus = title == 'Activate' ? 'Active' : 'Inactive';
        final updatedData = prop.toJson();
        updatedData['status'] = newStatus;
        context.read<PropertyBloc>().add(UpdateProperty(prop.id, updatedData));
      },
    );
  }

  Widget _buildGalleryHeader(PropertyModel property) {
    final images = property.images;
    final hasImages = images.isNotEmpty;

    if (!hasImages) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.indigo.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                property.type.toLowerCase() == 'villa'
                    ? Icons.holiday_village_rounded
                    : Icons.apartment_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      property.type.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    property.name,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (property.address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      property.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (idx) {
                setState(() => _currentImageIndex = idx);
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openFullScreenGallery(images, index, property.name),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 70,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            // Image count pill
            if (images.length > 1)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Expand button
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                  onPressed: () => _openFullScreenGallery(
                      images, _currentImageIndex, property.name),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(PropertyModel property) {
    final isActive = property.status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  property.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isActive ? Colors.green : Colors.orange)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      property.status,
                      style: TextStyle(
                        color: isActive ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  property.type.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (property.description != null && property.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              property.description!,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
          if (property.address != null && property.address!.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF717171), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    property.address!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _openMaps(property.address),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Maps', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKPIOverview(PropertyModel property) {
    int totalRooms = 0;
    int occupiedRooms = 0;
    double potentialMonthlyRevenue = 0;

    for (final floor in property.floors) {
      for (final room in floor.rooms) {
        totalRooms++;
        if (room.activeTenantsCount > 0 ||
            room.status.toLowerCase() == 'occupied') {
          occupiedRooms++;
        }
        if (room.defaultRent != null && room.defaultRent! > 0) {
          potentialMonthlyRevenue += room.defaultRent!;
        }
      }
    }
    for (final room in property.rooms) {
      totalRooms++;
      if (room.activeTenantsCount > 0 ||
          room.status.toLowerCase() == 'occupied') {
        occupiedRooms++;
      }
      if (room.defaultRent != null && room.defaultRent! > 0) {
        potentialMonthlyRevenue += room.defaultRent!;
      }
    }

    final vacantRooms = totalRooms - occupiedRooms;
    final occupancyRate =
        totalRooms > 0 ? (occupiedRooms / totalRooms) * 100 : 0.0;
    final currency = property.currency ?? 'QR';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Property Overview',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${occupancyRate.toStringAsFixed(0)}% Occupied',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalRooms > 0 ? (occupiedRooms / totalRooms) : 0,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2F92D0)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.meeting_room_outlined,
                  color: const Color(0xFF2F92D0),
                  title: 'Total Units',
                  value: '$totalRooms Units',
                  subtitle: '${property.floors.length} Floors',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.person_outline_rounded,
                  color: const Color(0xFF10B981),
                  title: 'Occupancy',
                  value: '$occupiedRooms Occupied',
                  subtitle: '$vacantRooms Vacant',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF2F92D0),
                  title: 'Est. Monthly Rent',
                  value: '$currency ${potentialMonthlyRevenue.toStringAsFixed(0)}',
                  subtitle: 'Potential gross',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.support_agent_rounded,
                  color: const Color(0xFF64748B),
                  title: 'Enquiries',
                  value: '${property.enquiries.length} Inquiries',
                  subtitle: 'Prospective leads',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(BuildContext context, PropertyModel property) {
    final amenities = property.amenities;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.spa_outlined, color: Color(0xFF2F92D0), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Property Amenities',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${amenities.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showPropertyAmenitiesDialog(context, property),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Manage', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF2F92D0),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (amenities.isEmpty)
            InkWell(
              onTap: () => _showPropertyAmenitiesDialog(context, property),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Color(0xFF2F92D0)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No amenities added yet. Tap to add amenities like Gym, Swimming Pool, Wi-Fi, etc.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map((amenity) {
                final icon = _getAmenityIcon(amenity);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: const Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        amenity,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showPropertyAmenitiesDialog(BuildContext context, PropertyModel property) {
    final standardAmenities = [
      'High-Speed Wi-Fi',
      'Swimming Pool',
      'Gym / Fitness Center',
      'Reserved Parking',
      '24/7 Security & CCTV',
      'Elevator / Lift',
      'Central Air Conditioning',
      'Power Backup Generator',
      'Maintenance Service',
      'Laundry Facility',
      'Garden / Balcony',
      'Waste Management',
    ];

    final Set<String> selected = Set.from(property.amenities);
    final customController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.spa_outlined, color: Color(0xFF2F92D0), size: 24),
                  SizedBox(width: 10),
                  Text('Manage Amenities',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select amenities available at this property:',
                        style: TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: standardAmenities.map((item) {
                          final isSel = selected.contains(item);
                          return FilterChip(
                            label: Text(item),
                            selected: isSel,
                            selectedColor: const Color(0xFFE0F2FE),
                            checkmarkColor: const Color(0xFF0284C7),
                            avatar: Icon(
                              _getAmenityIcon(item),
                              size: 16,
                              color: isSel ? const Color(0xFF0284C7) : Colors.grey,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSel ? const Color(0xFF0369A1) : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              setDialogState(() {
                                if (val) {
                                  selected.add(item);
                                } else {
                                  selected.remove(item);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Add Custom Amenity:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customController,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Squash Court, Sauna',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F92D0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                            onPressed: () {
                              final text = customController.text.trim();
                              if (text.isNotEmpty) {
                                setDialogState(() {
                                  selected.add(text);
                                  customController.clear();
                                });
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    final updatedData = property.toJson();
                    updatedData['amenities'] = selected.toList();
                    context.read<PropertyBloc>().add(
                          UpdateProperty(property.id, updatedData),
                        );
                  },
                  child: const Text('Save Amenities'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStructureInfo(BuildContext context, PropertyModel property) {
    int totalRooms = 0;
    for (final f in property.floors) {
      totalRooms += f.rooms.length;
    }
    totalRooms += property.rooms.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Floors & Units ($totalRooms)',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ManageFloorsRoomsPage(property: property),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded,
                          size: 17, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Manage',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap room to view details, or tap Manage to add/edit floors and rooms',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          if (property.floors.isEmpty && property.rooms.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No structure defined yet.',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
          ...property.floors.map((floor) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Floor ${floor.number}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${floor.rooms.length} Units',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (floor.rooms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('No rooms on this floor',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: floor.rooms.map((room) {
                        return _buildRoomBadge(context, property, room, floor.number);
                      }).toList(),
                    ),
                ],
              ),
            );
          }),
          // Direct rooms (Villa)
          if (property.rooms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Direct Units (${property.rooms.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: property.rooms.map((room) {
                return _buildRoomBadge(context, property, room, 'Direct');
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomBadge(
      BuildContext context, PropertyModel property, RoomModel room, String floorName) {
    final tenantCount = room.tenants.isNotEmpty ? room.tenants.length : room.activeTenantsCount;
    final isOccupied =
        tenantCount > 0 || room.status.toLowerCase() == 'occupied';
    final typeText = room.type.isNotEmpty ? ' (${room.type})' : '';
    final currency = property.currency ?? 'QR';

    return InkWell(
      onTap: () => _showRoomDetailsSheet(context, property, room, floorName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOccupied ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${room.number}$typeText',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: Color(0xFF1E293B),
              ),
            ),
            if (tenantCount > 1) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_outlined, size: 10.5, color: Color(0xFF2563EB)),
                    const SizedBox(width: 3),
                    Text(
                      '$tenantCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (room.defaultRent != null && room.defaultRent! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$currency ${room.defaultRent!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRoomDetailsSheet(
      BuildContext context, PropertyModel property, RoomModel room, String floorName) {
    final currency = property.currency ?? 'QR';
    final tenantCount = room.tenants.isNotEmpty ? room.tenants.length : room.activeTenantsCount;
    final isOccupied =
        tenantCount > 0 || room.status.toLowerCase() == 'occupied';
    final totalTenantsRent = room.tenants.fold<double>(0.0, (sum, t) => sum + (t.rentAmount ?? 0.0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Pull Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      children: [
                        // Room Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Room ${room.number}',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (!isOccupied
                                                  ? Colors.orange
                                                  : (tenantCount > 1
                                                      ? Colors.blue
                                                      : Colors.green))
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          !isOccupied
                                              ? 'Vacant'
                                              : (tenantCount > 1
                                                  ? 'Shared ($tenantCount Tenants)'
                                                  : 'Occupied (1 Tenant)'),
                                          style: TextStyle(
                                            color: !isOccupied
                                                ? Colors.orange.shade800
                                                : (tenantCount > 1
                                                    ? Colors.blue.shade800
                                                    : Colors.green.shade800),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${property.name} · Floor $floorName · ${room.type.isNotEmpty ? room.type : "Standard Room"}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // Financial Info
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tenantCount > 1 ? 'Total Collected Rent' : 'Default Rent',
                                      style: const TextStyle(
                                          fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tenantCount > 1 && totalTenantsRent > 0
                                          ? '$currency ${totalTenantsRent.toStringAsFixed(0)}'
                                          : (room.defaultRent != null && room.defaultRent! > 0
                                              ? '$currency ${room.defaultRent!.toStringAsFixed(0)}'
                                              : 'Not configured'),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      tenantCount > 1
                                          ? 'Sum across $tenantCount tenants'
                                          : '/ month',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Default Deposit',
                                        style: TextStyle(
                                            fontSize: 11, color: Color(0xFF64748B))),
                                    const SizedBox(height: 4),
                                    Text(
                                      room.defaultDeposit != null && room.defaultDeposit! > 0
                                          ? '$currency ${room.defaultDeposit!.toStringAsFixed(0)}'
                                          : 'Not configured',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Text('Security guarantee',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Room-Specific Amenities & Services
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.room_service_outlined,
                                      color: Colors.indigo, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Room Amenities & Services',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${room.amenities.length}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _showRoomAmenitiesDialog(context, property, room);
                              },
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: const Text('Manage',
                                  style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: Colors.indigo,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (room.amenities.isEmpty)
                          InkWell(
                            onTap: () =>
                                _showRoomAmenitiesDialog(context, property, room),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.indigo.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      color: Colors.indigo.shade600, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No room-specific amenities or services added. Tap to add Attached Bath, Balcony, Cleaning, etc.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: room.amenities.map((item) {
                              final icon = _getAmenityIcon(item);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.indigo.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 15, color: Colors.indigo),
                                    const SizedBox(width: 6),
                                    Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Room Tenants List
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.people_alt_outlined,
                                      color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      room.tenants.length > 1
                                          ? 'Room Tenants (${room.tenants.length})'
                                          : 'Room Tenants (${room.tenants.length})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(sheetCtx);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddPersonPage(
                                      initialRole: AppConstants.tenant,
                                      initialPropertyId: property.id,
                                      initialRoomId: room.id,
                                    ),
                                  ),
                                );
                                if (result == true && context.mounted) {
                                  context.read<PropertyBloc>().add(const LoadProperties(isRefresh: true));
                                }
                              },
                              icon: Icon(
                                room.tenants.isEmpty ? Icons.person_add_alt_1 : Icons.group_add_outlined,
                                size: 14,
                              ),
                              label: Text(
                                room.tenants.isEmpty ? 'Assign Tenant' : 'Add Co-Tenant',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (room.tenants.length > 1) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.groups_rounded, size: 20, color: Color(0xFF2563EB)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Shared Unit / Co-Living: ${room.tenants.length} tenants are registered to Room ${room.number}.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (room.tenants.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.person_off_outlined,
                                    size: 40, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text(
                                  'No tenants currently assigned to this room.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You can assign a new or existing tenant to this unit.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(sheetCtx);
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddPersonPage(
                                          initialRole: AppConstants.tenant,
                                          initialPropertyId: property.id,
                                          initialRoomId: room.id,
                                        ),
                                      ),
                                    );
                                    if (result == true && context.mounted) {
                                      context.read<PropertyBloc>().add(const LoadProperties(isRefresh: true));
                                    }
                                  },
                                  icon: const Icon(Icons.person_add_outlined,
                                      size: 16),
                                  label: const Text('Add Tenant to This Room'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          ...room.tenants.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final tenant = entry.value;
                            return _buildTenantCard(
                              context,
                              property,
                              room,
                              tenant,
                              tenantIndex: room.tenants.length > 1 ? idx + 1 : null,
                              totalTenants: room.tenants.length,
                            );
                          }),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(sheetCtx);
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddPersonPage(
                                        initialRole: AppConstants.tenant,
                                        initialPropertyId: property.id,
                                        initialRoomId: room.id,
                                      ),
                                    ),
                                  );
                                  if (result == true && context.mounted) {
                                    context.read<PropertyBloc>().add(const LoadProperties(isRefresh: true));
                                  }
                                },
                                icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                                label: Text('Add Another Co-Tenant to Room ${room.number}'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                  side: BorderSide(color: Colors.blue.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTenantCard(
      BuildContext context,
      PropertyModel property,
      RoomModel room,
      RoomTenantModel tenant, {
      int? tenantIndex,
      int? totalTenants,
  }) {
    final currency = property.currency ?? 'QR';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tenantIndex != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_pin_outlined, size: 13, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        'Co-Tenant $tenantIndex of $totalTenants',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (tenant.status.toLowerCase() == 'active'
                            ? Colors.green
                            : Colors.orange)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tenant.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tenant.status.toLowerCase() == 'active'
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.withValues(alpha: 0.12),
                child: Text(
                  tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : 'T',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (tenant.email != null && tenant.email!.isNotEmpty)
                      Text(
                        tenant.email!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.blue, size: 19),
                onPressed: () => _makePhoneCall(tenant.phone),
                tooltip: 'Call Tenant',
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_rounded,
                    color: Color(0xFF25D366), size: 19),
                onPressed: () => _openWhatsApp(tenant.phone, 'Room ${room.number}'),
                tooltip: 'WhatsApp Tenant',
              ),
            ],
          ),
          const Divider(height: 20),
          // Qatar ID Row (Important Client Requirement!)
          if (tenant.qatarId != null && tenant.qatarId!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 16, color: Colors.indigo),
                  const SizedBox(width: 6),
                  const Text(
                    'Qatar ID: ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                  Expanded(
                    child: Text(
                      tenant.qatarId!,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () =>
                        _copyToClipboard(tenant.qatarId!, 'Qatar ID'),
                    child: const Icon(Icons.copy_rounded,
                        size: 15, color: Colors.indigo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Rent & Deposit Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (tenant.rentAmount != null && tenant.rentAmount! > 0)
                Text(
                  'Rent: $currency ${tenant.rentAmount!.toStringAsFixed(0)} / mo',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              if (tenant.securityDeposit != null && tenant.securityDeposit! > 0)
                Text(
                  'Deposit: $currency ${tenant.securityDeposit!.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
            ],
          ),
          if (tenant.contractStartDate != null || tenant.contractEndDate != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (tenant.contractStartDate != null)
                  Text(
                    'Start: ${tenant.contractStartDate!.split('T')[0]}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                if (tenant.contractEndDate != null)
                  Text(
                    'End: ${tenant.contractEndDate!.split('T')[0]}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final tenantModel = TenantModel(
                  id: tenant.id,
                  name: tenant.name,
                  phone: tenant.phone,
                  email: tenant.email,
                  qatarId: tenant.qatarId,
                  assignedPropertyId: property.id,
                  assignedRoomId: room.id,
                  rentAmount: tenant.rentAmount ?? 0.0,
                  securityDeposit: tenant.securityDeposit ?? 0.0,
                  status: tenant.status,
                  contractStartDate: tenant.contractStartDate != null
                      ? (DateTime.tryParse(tenant.contractStartDate!) ??
                          DateTime.now())
                      : DateTime.now(),
                  contractEndDate: tenant.contractEndDate != null
                      ? DateTime.tryParse(tenant.contractEndDate!)
                      : null,
                );
                Navigator.pushNamed(
                  context,
                  AppRoutes.personDetails,
                  arguments: tenantModel,
                );
              },
              icon: const Icon(Icons.visibility_outlined, size: 15),
              label: const Text('View Full Tenant Profile',
                  style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[700],
                side: BorderSide(color: Colors.blue.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomAmenitiesDialog(
      BuildContext context, PropertyModel property, RoomModel room) {
    final standardRoomAmenities = [
      'Attached Bathroom',
      'Private Balcony',
      'High-Speed Wi-Fi',
      'Air Conditioner',
      'Smart TV',
      'Wardrobe / Closet',
      'Mini Refrigerator',
      'Work Desk & Chair',
      'Daily Cleaning Service',
      'Weekly Housekeeping',
      'Laundry Service',
      'Water & Electricity Included',
    ];

    final Set<String> selected = Set.from(room.amenities);
    final customController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.room_service_outlined,
                      color: Colors.indigo, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Room ${room.number} Amenities',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select amenities and services for this specific unit:',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: standardRoomAmenities.map((item) {
                          final isSel = selected.contains(item);
                          return FilterChip(
                            label: Text(item),
                            selected: isSel,
                            selectedColor: Colors.indigo.shade100,
                            checkmarkColor: Colors.indigo.shade800,
                            avatar: Icon(
                              _getAmenityIcon(item),
                              size: 15,
                              color: isSel ? Colors.indigo.shade800 : Colors.grey,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSel ? Colors.indigo.shade900 : Colors.black87,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              setDialogState(() {
                                if (val) {
                                  selected.add(item);
                                } else {
                                  selected.remove(item);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Add Custom Room Service / Amenity:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customController,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Linen Change, Microwave',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                            onPressed: () {
                              final text = customController.text.trim();
                              if (text.isNotEmpty) {
                                setDialogState(() {
                                  selected.add(text);
                                  customController.clear();
                                });
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    context.read<PropertyBloc>().add(
                          UpdateRoom(
                            propertyId: property.id,
                            roomId: room.id,
                            roomData: {'amenities': selected.toList()},
                          ),
                        );
                  },
                  child: const Text('Save Room Amenities'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getAmenityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi_rounded;
    } else if (lower.contains('pool')) {
      return Icons.pool_rounded;
    } else if (lower.contains('gym') || lower.contains('fitness')) {
      return Icons.fitness_center_rounded;
    } else if (lower.contains('park')) {
      return Icons.local_parking_rounded;
    } else if (lower.contains('secur') || lower.contains('cctv')) {
      return Icons.security_rounded;
    } else if (lower.contains('lift') || lower.contains('elevator')) {
      return Icons.elevator_rounded;
    } else if (lower.contains('ac') ||
        lower.contains('air') ||
        lower.contains('cool')) {
      return Icons.ac_unit_rounded;
    } else if (lower.contains('power') || lower.contains('backup')) {
      return Icons.bolt_rounded;
    } else if (lower.contains('clean') ||
        lower.contains('maid') ||
        lower.contains('housekeep')) {
      return Icons.cleaning_services_rounded;
    } else if (lower.contains('laundr') || lower.contains('wash')) {
      return Icons.local_laundry_service_rounded;
    } else if (lower.contains('balcon') || lower.contains('terrace')) {
      return Icons.balcony_outlined;
    } else if (lower.contains('bath')) {
      return Icons.bathtub_outlined;
    } else if (lower.contains('tv')) {
      return Icons.tv_rounded;
    } else if (lower.contains('wardrobe') || lower.contains('closet')) {
      return Icons.checkroom_rounded;
    } else if (lower.contains('fridge') || lower.contains('refrigerat')) {
      return Icons.kitchen_rounded;
    } else if (lower.contains('desk') || lower.contains('work')) {
      return Icons.desk_rounded;
    } else if (lower.contains('utilit') ||
        lower.contains('water') ||
        lower.contains('electr')) {
      return Icons.water_drop_outlined;
    } else if (lower.contains('waste')) {
      return Icons.delete_sweep_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  Widget _buildEnquiriesInfo(PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: Color(0xFF2F92D0), size: 20),
              const SizedBox(width: 8),
              Text(
                'Customer Enquiries (${property.enquiries.length})',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (property.enquiries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No customer enquiries yet for this property.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
              ),
            )
          else
            ...property.enquiries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFF1F5F9),
                        child: Text(
                          e.name.isNotEmpty ? e.name[0].toUpperCase() : 'E',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Color(0xFF2F92D0)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            Text(
                              'Phone: ${e.phone}${e.details != null ? " · ${e.details}" : ""}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Color(0xFF2F92D0), size: 18),
                        onPressed: () => _makePhoneCall(e.phone),
                        tooltip: 'Call',
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_rounded,
                            color: Color(0xFF25D366), size: 18),
                        onPressed: () => _openWhatsApp(e.phone, property.name),
                        tooltip: 'WhatsApp',
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildExpensesInfo(PropertyModel property) {
    final currency = property.currency ?? 'QR';
    double totalMonthlyExpenses = 0;
    for (final exp in property.propertyExpenses) {
      totalMonthlyExpenses += exp.amount;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recurring Expenses',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (totalMonthlyExpenses > 0)
                Text(
                  'Total: $currency ${totalMonthlyExpenses.toStringAsFixed(0)} / mo',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (property.propertyExpenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No recurring property expenses registered.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
              ),
            )
          else
            ...property.propertyExpenses.map((exp) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(exp.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        '$currency ${exp.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: PageView.builder(
        itemCount: images.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                images[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
