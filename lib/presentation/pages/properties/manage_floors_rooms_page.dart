import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/property_model.dart';
import '../../blocs/property/property_bloc.dart';

class ManageFloorsRoomsPage extends StatefulWidget {
  final PropertyModel property;
  final bool openAddFloorOnLaunch;
  final bool openAddRoomOnLaunch;

  const ManageFloorsRoomsPage({
    super.key,
    required this.property,
    this.openAddFloorOnLaunch = false,
    this.openAddRoomOnLaunch = false,
  });

  @override
  State<ManageFloorsRoomsPage> createState() => _ManageFloorsRoomsPageState();
}

class _ManageFloorsRoomsPageState extends State<ManageFloorsRoomsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.openAddFloorOnLaunch) {
        _showAddFloorDialog(context, widget.property);
      } else if (widget.openAddRoomOnLaunch) {
        _showAddRoomDialog(context, widget.property);
      }
    });
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PropertyBloc, PropertyState>(
      listener: (context, state) {
        if (state is PropertyLoaded) {
          if (state.operationError != null) {
            _showToast(state.operationError!, isError: true);
          } else if (state.operationSuccess != null) {
            _showToast(state.operationSuccess!);
          }
        } else if (state is PropertyError) {
          _showToast(state.message, isError: true);
        }
      },
      builder: (context, state) {
        PropertyModel currentProperty = widget.property;
        if (state is PropertyLoaded) {
          currentProperty = state.properties.firstWhere(
            (p) => p.id == widget.property.id,
            orElse: () => widget.property,
          );
        }

        final int totalRooms = currentProperty.floors.fold(
              0,
              (sum, f) => sum + f.rooms.length,
            ) +
            currentProperty.rooms.length;

        final int occupiedRooms = currentProperty.floors.fold(
              0,
              (sum, f) =>
                  sum +
                  f.rooms
                      .where((r) =>
                          r.activeTenantsCount > 0 ||
                          r.status.toLowerCase() == 'occupied')
                      .length,
            ) +
            currentProperty.rooms
                .where((r) =>
                    r.activeTenantsCount > 0 ||
                    r.status.toLowerCase() == 'occupied')
                .length;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black87),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Floors & Units',
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  currentProperty.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () {
                  context.read<PropertyBloc>().add(const LoadProperties());
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderOverview(currentProperty, totalRooms, occupiedRooms),
                const SizedBox(height: 16),
                _buildActionButtons(currentProperty),
                const SizedBox(height: 20),
                if (currentProperty.floors.isEmpty && currentProperty.rooms.isEmpty)
                  _buildEmptyState(currentProperty)
                else ...[
                  ...currentProperty.floors.map((floor) {
                    return _buildFloorCard(context, currentProperty, floor);
                  }),
                  if (currentProperty.rooms.isNotEmpty)
                    _buildUnassignedRoomsCard(context, currentProperty),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderOverview(
      PropertyModel property, int totalRooms, int occupiedRooms) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  property.type.toUpperCase(),
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
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.layers_outlined,
                  color: Colors.blue,
                  title: 'Floors',
                  value: '${property.floors.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.meeting_room_outlined,
                  color: Colors.indigo,
                  title: 'Total Units',
                  value: '$totalRooms',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.person_outline,
                  color: Colors.green,
                  title: 'Occupied',
                  value: '$occupiedRooms',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PropertyModel property) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddFloorDialog(context, property),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Floor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showAddRoomDialog(context, property),
            icon: const Icon(Icons.add_home_outlined, size: 18),
            label: const Text('Add Unit / Room'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[800],
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(PropertyModel property) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_clear_outlined, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Floors or Units Defined',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Begin structuring this property by adding your first floor and its units.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddFloorDialog(context, property),
            icon: const Icon(Icons.add),
            label: const Text('Add First Floor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorCard(
      BuildContext context, PropertyModel property, FloorModel floor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Floor ${floor.number}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '${floor.rooms.length} Units',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showAddRoomDialog(
                        context,
                        property,
                        defaultFloor: floor,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.add_box_outlined,
                            size: 20, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          _showEditFloorDialog(context, property, floor),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.edit_outlined,
                            size: 19, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          _showDeleteFloorConfirmation(context, floor),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline,
                            size: 20, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: floor.rooms.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'No units on this floor yet.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showAddRoomDialog(
                              context,
                              property,
                              defaultFloor: floor,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Room to this floor'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: floor.rooms.map((room) {
                      return _buildRoomTile(context, property, floor, room);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedRoomsCard(
      BuildContext context, PropertyModel property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Standalone Units (${property.rooms.length})',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: property.rooms.map((room) {
                return _buildRoomTile(context, property, null, room);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _buildRentDepositString(RoomModel room, String currency) {
    final parts = <String>[];
    if (room.defaultRent != null && room.defaultRent! > 0) {
      parts.add('Rent: $currency ${room.defaultRent!.toStringAsFixed(0)}');
    } else {
      parts.add('Rent: Not set');
    }
    if (room.defaultDeposit != null && room.defaultDeposit! > 0) {
      parts.add('Dep: $currency ${room.defaultDeposit!.toStringAsFixed(0)}');
    }
    return parts.join(' • ');
  }

  Widget _buildRoomTile(
    BuildContext context,
    PropertyModel property,
    FloorModel? floor,
    RoomModel room,
  ) {
    final currency = property.currency ?? 'QR';
    final tenantCount = room.tenants.isNotEmpty ? room.tenants.length : room.activeTenantsCount;
    final isOccupied =
        tenantCount > 0 || room.status.toLowerCase() == 'occupied';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_rounded,
            color: isOccupied ? const Color(0xFF10B981) : const Color(0xFF2F92D0),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Room ${room.number}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (room.type.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          room.type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isOccupied ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        !isOccupied
                            ? 'Vacant'
                            : tenantCount > 1
                                ? 'Shared ($tenantCount)'
                                : 'Occupied',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOccupied
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildRentDepositString(room, currency),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[700],
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
          InkWell(
            onTap: () => _showEditRoomDialog(context, property, room),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.edit_outlined, size: 19, color: Colors.blue),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: isOccupied
                ? () {
                    _showToast(
                      'Cannot delete unit with active tenants',
                      isError: true,
                    );
                  }
                : () => _showDeleteRoomConfirmation(context, room),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.delete_outline,
                size: 19,
                color: isOccupied ? Colors.grey[350] : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS ---

  void _showAddFloorDialog(BuildContext context, PropertyModel property) {
    final controller = TextEditingController();
    // Default to next number
    int nextNumber = property.floors.length;
    controller.text = nextNumber.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.layers, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Add Floor',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter floor number or name for "${property.name}":',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Floor Number / Label',
                hintText: 'e.g. 0, 1, 2, Ground Floor',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isEmpty) {
                _showToast('Floor number cannot be empty', isError: true);
                return;
              }
              Navigator.pop(ctx);
              context.read<PropertyBloc>().add(
                    AddFloor(propertyId: property.id, floorNumber: val),
                  );
            },
            child: const Text('Add Floor'),
          ),
        ],
      ),
    );
  }

  void _showEditFloorDialog(
      BuildContext context, PropertyModel property, FloorModel floor) {
    final controller = TextEditingController(text: floor.number);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Floor',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Floor Number / Label',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isEmpty) {
                _showToast('Floor number cannot be empty', isError: true);
                return;
              }
              Navigator.pop(ctx);
              context.read<PropertyBloc>().add(
                    UpdateFloor(floorId: floor.id, floorNumber: val),
                  );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFloorConfirmation(BuildContext context, FloorModel floor) {
    if (floor.rooms.any((r) =>
        r.activeTenantsCount > 0 || r.status.toLowerCase() == 'occupied')) {
      _showToast(
        'Cannot delete floor with occupied rooms',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Floor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          'Are you sure you want to delete Floor ${floor.number}? All ${floor.rooms.length} vacant rooms on this floor will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PropertyBloc>().add(DeleteFloor(floor.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog(
    BuildContext context,
    PropertyModel property, {
    FloorModel? defaultFloor,
  }) {
    if (property.floors.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('No Floors Available'),
          content: const Text(
            'Please add at least one floor before adding rooms to this property.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddFloorDialog(context, property);
              },
              child: const Text('Add Floor Now'),
            ),
          ],
        ),
      );
      return;
    }

    String selectedFloorId =
        defaultFloor?.id ?? property.floors.first.id;
    final numberController = TextEditingController();
    final rentController = TextEditingController();
    final depositController = TextEditingController();

    final roomTypes = [
      '1 BHK',
      '2 BHK',
      '3 BHK',
      'Studio',
      'Single Room',
      'Master Bedroom',
      'Luxury Suite',
      'Office',
      'Shop',
    ];
    String selectedType = roomTypes.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Unit / Room',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFloorId,
                      decoration: const InputDecoration(
                        labelText: 'Select Floor',
                        prefixIcon: Icon(Icons.layers_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: property.floors.map((f) {
                        return DropdownMenuItem(
                          value: f.id,
                          child: Text('Floor ${f.number}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedFloorId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Unit / Room Number *',
                        hintText: 'e.g. 101, Apt 4B, Room 3',
                        prefixIcon: Icon(Icons.tag),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Unit Type',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: roomTypes.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Rent (${property.currency ?? 'QR'})',
                              prefixIcon:
                                  const Icon(Icons.account_balance_wallet_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: depositController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText:
                                  'Deposit (${property.currency ?? 'QR'})',
                              prefixIcon: const Icon(Icons.shield_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        final number = numberController.text.trim();
                        if (number.isEmpty) {
                          _showToast('Unit number is required', isError: true);
                          return;
                        }

                        final floor = property.floors.firstWhere(
                          (f) => f.id == selectedFloorId,
                          orElse: () => property.floors.first,
                        );

                        final rent = double.tryParse(rentController.text.trim());
                        final deposit =
                            double.tryParse(depositController.text.trim());

                        final payload = {
                          'number': number,
                          'floorId': selectedFloorId,
                          'floorName': 'Floor ${floor.number}',
                          'type': selectedType,
                          if (rent != null) 'defaultRent': rent,
                          if (deposit != null) 'defaultDeposit': deposit,
                          'amenities': [],
                        };

                        Navigator.pop(sheetCtx);
                        context.read<PropertyBloc>().add(
                              AddRoom(
                                propertyId: property.id,
                                roomData: payload,
                              ),
                            );
                      },
                      child: Text(
                        'Add Unit',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditRoomDialog(
    BuildContext context,
    PropertyModel property,
    RoomModel room,
  ) {
    final numberController = TextEditingController(text: room.number);
    final rentController = TextEditingController(
      text: room.defaultRent != null ? room.defaultRent!.toStringAsFixed(0) : '',
    );
    final depositController = TextEditingController(
      text: room.defaultDeposit != null
          ? room.defaultDeposit!.toStringAsFixed(0)
          : '',
    );

    final roomTypes = [
      '1 BHK',
      '2 BHK',
      '3 BHK',
      'Studio',
      'Single Room',
      'Master Bedroom',
      'Luxury Suite',
      'Office',
      'Shop',
    ];
    String selectedType =
        roomTypes.contains(room.type) ? room.type : roomTypes.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Unit ${room.number}',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Unit / Room Number *',
                        prefixIcon: Icon(Icons.tag),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Unit Type',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: roomTypes.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Rent (${property.currency ?? 'QR'})',
                              prefixIcon:
                                  const Icon(Icons.account_balance_wallet_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: depositController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText:
                                  'Deposit (${property.currency ?? 'QR'})',
                              prefixIcon: const Icon(Icons.shield_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        final number = numberController.text.trim();
                        if (number.isEmpty) {
                          _showToast('Unit number cannot be empty', isError: true);
                          return;
                        }

                        final rent = double.tryParse(rentController.text.trim());
                        final deposit =
                            double.tryParse(depositController.text.trim());

                        final payload = {
                          'number': number,
                          'type': selectedType,
                          if (rent != null) 'defaultRent': rent,
                          if (deposit != null) 'defaultDeposit': deposit,
                        };

                        Navigator.pop(sheetCtx);
                        context.read<PropertyBloc>().add(
                              UpdateRoom(
                                propertyId: property.id,
                                roomId: room.id,
                                roomData: payload,
                              ),
                            );
                      },
                      child: Text(
                        'Update Unit',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteRoomConfirmation(BuildContext context, RoomModel room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Unit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          'Are you sure you want to delete Unit "${room.number}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PropertyBloc>().add(DeleteRoom(room.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
