import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/amenity/amenity_bloc.dart';
import '../../blocs/amenity/amenity_event.dart';
import '../../blocs/amenity/amenity_state.dart';
import '../../../core/models/amenity_model.dart';

class AmenitiesPage extends StatefulWidget {
  const AmenitiesPage({super.key});

  @override
  State<AmenitiesPage> createState() => _AmenitiesPageState();
}

class _AmenitiesPageState extends State<AmenitiesPage> {
  void _showCreateEditDialog({AmenityModel? amenity}) {
    final formKey = GlobalKey<FormState>();
    String name = amenity?.name ?? '';
    String category = amenity?.category ?? 'Other';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(amenity == null ? 'Create Amenity' : 'Edit Amenity',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder()),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => name = val ?? '',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Category', border: OutlineInputBorder()),
                  value: category,
                  items: ['Health', 'Parking', 'Leisure', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => category = val ?? 'Other',
                  onSaved: (val) => category = val ?? 'Other',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  if (amenity == null) {
                    context
                        .read<AmenityBloc>()
                        .add(CreateAmenity(name: name, category: category));
                  } else {
                    context.read<AmenityBloc>().add(UpdateAmenity(
                        id: amenity.id, name: name, category: category));
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  void _showDeleteDialog(AmenityModel amenity) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Amenity',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete ${amenity.name}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                context.read<AmenityBloc>().add(DeleteAmenity(amenity.id));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AmenityBloc, AmenityState>(
      listener: (context, state) {
        if (state is AmenitySuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green));
        } else if (state is AmenityError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text('Amenities Management',
              style: GoogleFonts.montserrat(
                  color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateEditDialog(),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('All Amenities',
                      style: GoogleFonts.montserrat(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  BlocBuilder<AmenityBloc, AmenityState>(
                    builder: (context, state) {
                      if (state is AmenityLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is AmenitiesLoaded) {
                        if (state.amenities.isEmpty) {
                          return const Center(
                              child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No amenities found.'),
                          ));
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor:
                                WidgetStateProperty.all(Colors.grey[100]),
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Repairs Req.')),
                              DataColumn(label: Text('Repairs Comp.')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: state.amenities.map((amn) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(amn.name)),
                                  DataCell(Text(amn.category)),
                                  DataCell(Text(
                                      amn.repairsRequested.toString())),
                                  DataCell(Text(
                                      amn.repairsCompleted.toString())),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue, size: 20),
                                          onPressed: () =>
                                              _showCreateEditDialog(
                                                  amenity: amn),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red, size: 20),
                                          onPressed: () =>
                                              _showDeleteDialog(amn),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      }
                      return const Center(
                          child: Text('Failed to load amenities'));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
