import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/property_model.dart';

part 'add_property_state.dart';

class AddPropertyCubit extends Cubit<AddPropertyState> {
  AddPropertyCubit() : super(const AddPropertyState());

  void initFromProperty(PropertyModel property) {
    // Map existing floors and rooms
    final List<Map<String, dynamic>> initialFloors = [];
    final Set<String> existingTypes = {};

    for (var floor in property.floors) {
      initialFloors.add({
        'id': floor.id,
        'name': floor.number, // FloorModel only has 'number'
        'number': floor.number,
        'rooms': floor.rooms.map((r) {
          if (r.type.isNotEmpty) existingTypes.add(r.type);
          return {
            'id': r.id,
            'number': r.number,
            'status': r.status,
            'type': r.type,
            'rent': r.defaultRent ?? 0.0,
            'deposit': r.defaultDeposit ?? 0.0,
            'rentAmount': r.defaultRent,
            'depositAmount': r.defaultDeposit,
          };
        }).toList(),
      });
    }

    final List<Map<String, dynamic>> initialExpenses = [];
    if (property.propertyExpenses.isNotEmpty) {
      for (var exp in property.propertyExpenses) {
        initialExpenses.add({
          'id': exp.id,
          'name': exp.name,
          'amount': exp.amount,
        });
      }
    }

    // Determine room types: default base types according to property type + any custom existing types
    final List<String> roomTypesList = [];
    if (property.type.toUpperCase() == AppConstants.propertyTypeVilla) {
      roomTypesList.addAll(['Master Bedroom', 'Bedroom', 'Guest Room', 'Maid Room', 'Suite', 'Studio']);
    } else {
      roomTypesList.addAll(['1 BHK', '2 BHK', '3 BHK', 'Studio', 'Master Bedroom', 'Standard']);
    }
    for (var t in existingTypes) {
      if (!roomTypesList.any((x) => x.toLowerCase() == t.toLowerCase())) {
        roomTypesList.add(t);
      }
    }

    emit(state.copyWith(
      name: property.name,
      selectedType: property.type,
      description: property.description ?? '',
      address: property.address ?? '',
      buildingFloors: initialFloors,
      propertyExpenses: initialExpenses,
      managerName: property.managerName,
      managerPhone: property.managerPhone,
      managerEmail: property.managerEmail,
      availableRoomTypes: roomTypesList,
      amenities: property.amenities,
    ));
  }

  void updateBasicInfo({
    String? name,
    String? description,
  }) {
    emit(state.copyWith(
      name: name,
      description: description,
      errorMessage: null,
    ));
  }

  void updateManagerInfo({
    String? managerName,
    String? managerPhone,
    String? managerEmail,
  }) {
    emit(state.copyWith(
      managerName: managerName,
      managerPhone: managerPhone,
      managerEmail: managerEmail,
      errorMessage: null,
    ));
  }

  void updateLocationInfo({
    String? address,
    String? lat,
    String? long,
    String? country,
    String? stateText,
    String? city,
    String? pincode,
  }) {
    emit(state.copyWith(
      address: address,
      lat: lat,
      long: long,
      country: country,
      stateText: stateText,
      city: city,
      pincode: pincode,
      errorMessage: null,
    ));
  }

  void updateType(String type) {
    List<String> types = List<String>.from(state.availableRoomTypes);
    // If switching between Flat and Villa, adapt the default room types
    if (type.toUpperCase() == AppConstants.propertyTypeVilla) {
      const villaDefaults = ['Master Bedroom', 'Bedroom', 'Guest Room', 'Maid Room', 'Suite', 'Studio'];
      for (final vd in villaDefaults) {
        if (!types.any((t) => t.toLowerCase() == vd.toLowerCase())) {
          types.add(vd);
        }
      }
    } else {
      const flatDefaults = ['1 BHK', '2 BHK', '3 BHK', 'Studio', 'Master Bedroom', 'Standard'];
      for (final fd in flatDefaults) {
        if (!types.any((t) => t.toLowerCase() == fd.toLowerCase())) {
          types.add(fd);
        }
      }
    }

    emit(state.copyWith(
      selectedType: type,
      availableRoomTypes: types,
      errorMessage: null,
    ));
  }

  void updateCurrency(String currency) {
    emit(state.copyWith(currency: currency, errorMessage: null));
  }

  // --- Image Management ---
  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> selectedImages = await picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      final List<XFile> currentImages = List<XFile>.from(state.images);
      currentImages.addAll(selectedImages);
      // Limit to 5 images
      final updatedImages = currentImages.take(5).toList();
      emit(state.copyWith(images: updatedImages, errorMessage: null));
    }
  }

  void removeImage(int index) {
    final currentImages = List<XFile>.from(state.images);
    currentImages.removeAt(index);
    emit(state.copyWith(images: currentImages, errorMessage: null));
  }

  // --- Flat / Room Management ---

  void addFloor(String name, String number) {
    final newFloors = List<Map<String, dynamic>>.from(state.buildingFloors);
    newFloors.add({
      'name': name,
      'number': number,
      'rooms': <Map<String, dynamic>>[],
    });
    emit(state.copyWith(buildingFloors: newFloors));
  }

  void removeFloor(int index) {
    final newFloors = List<Map<String, dynamic>>.from(state.buildingFloors);
    newFloors.removeAt(index);
    emit(state.copyWith(buildingFloors: newFloors));
  }

  void updateFloorName(int index, String name, String number) {
    final newFloors = List<Map<String, dynamic>>.from(state.buildingFloors);
    newFloors[index] = {...newFloors[index], 'name': name, 'number': number};
    emit(state.copyWith(buildingFloors: newFloors));
  }

  void addRoomType(String type) {
    final trimmed = type.trim();
    if (trimmed.isEmpty) return;
    final currentTypes = List<String>.from(state.availableRoomTypes);
    if (!currentTypes.any((t) => t.toLowerCase() == trimmed.toLowerCase())) {
      currentTypes.add(trimmed);
      emit(state.copyWith(availableRoomTypes: currentTypes));
    }
  }

  void removeRoomType(String type) {
    final currentTypes = List<String>.from(state.availableRoomTypes);
    currentTypes.remove(type);
    emit(state.copyWith(availableRoomTypes: currentTypes));
  }

  void addUnitToFloor(int floorIndex, Map<String, dynamic> unitData) {
    final newFloors = List<Map<String, dynamic>>.from(state.buildingFloors);
    final rooms = List<Map<String, dynamic>>.from(newFloors[floorIndex]['rooms']);
    rooms.add(unitData);
    newFloors[floorIndex] = {...newFloors[floorIndex], 'rooms': rooms};

    // If unitData['type'] is a new custom type, also add it to available room types
    final String rType = (unitData['type'] ?? '').toString().trim();
    List<String>? updatedTypes;
    if (rType.isNotEmpty && !state.availableRoomTypes.any((t) => t.toLowerCase() == rType.toLowerCase())) {
      updatedTypes = List<String>.from(state.availableRoomTypes)..add(rType);
    }

    emit(state.copyWith(
      buildingFloors: newFloors,
      availableRoomTypes: updatedTypes ?? state.availableRoomTypes,
    ));
  }

  void removeUnitFromFloor(int floorIndex, int roomIndex) {
    final newFloors = List<Map<String, dynamic>>.from(state.buildingFloors);
    final rooms = List<Map<String, dynamic>>.from(newFloors[floorIndex]['rooms']);
    rooms.removeAt(roomIndex);
    newFloors[floorIndex] = {...newFloors[floorIndex], 'rooms': rooms};
    emit(state.copyWith(buildingFloors: newFloors));
  }
  
  // --- Expense Management ---
  void addPropertyExpense(String name, double amount) {
    final expenses = List<Map<String, dynamic>>.from(state.propertyExpenses);
    expenses.add({'name': name, 'amount': amount});
    emit(state.copyWith(propertyExpenses: expenses));
  }

  void removePropertyExpense(int index) {
    final expenses = List<Map<String, dynamic>>.from(state.propertyExpenses);
    expenses.removeAt(index);
    emit(state.copyWith(propertyExpenses: expenses));
  }

  // Navigation & Validation
  bool validateStep1() {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Property Name is required'));
      return false;
    }
    if (state.selectedType.isEmpty) {
      emit(state.copyWith(errorMessage: 'Property Type is required'));
      return false;
    }
    emit(state.copyWith(errorMessage: null));
    return true;
  }

  bool validateStep2() {
    if (state.buildingFloors.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please add at least one floor'));
      return false;
    }
    // Check if every floor has at least one room? 
    // Usually properties need at least one room
    bool hasAnyRoom = state.buildingFloors.any((floor) => (floor['rooms'] as List).isNotEmpty);
    if (!hasAnyRoom) {
      emit(state.copyWith(errorMessage: 'Please add at least one room/unit to the property'));
      return false;
    }
    emit(state.copyWith(errorMessage: null));
    return true;
  }

  void nextStep() {
    if (state.currentStep == 1 && validateStep1()) {
      emit(state.copyWith(currentStep: 2));
    } else if (state.currentStep == 2 && validateStep2()) {
      emit(state.copyWith(currentStep: 3));
    }
  }

  void prevStep() {
    if (state.currentStep > 1) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  Map<String, dynamic>? validateAndGetSubmissionData() {
    final Map<String, dynamic> propertyData = {
      'name': state.name,
      'type': state.selectedType,
      'description': state.description,
      'address': state.address,
      'lat': state.lat,
      'long': state.long,
      'country': state.country,
      'state': state.stateText,
      'city': state.city,
      'pincode': state.pincode,
      'currency': state.currency,
      'managerName': state.managerName,
      'managerPhone': state.managerPhone,
      'managerEmail': state.managerEmail,
      'floors': state.buildingFloors,
      'propertyExpenses': state.propertyExpenses,
      'status': 'Active',
      'images': state.images,
      'amenities': state.amenities,
    };

    return propertyData;
  }

  void toggleAmenity(String amenity) {
    final current = List<String>.from(state.amenities);
    if (current.contains(amenity)) {
      current.remove(amenity);
    } else {
      current.add(amenity);
    }
    emit(state.copyWith(amenities: current));
  }

  void addCustomAmenity(String amenity) {
    final trimmed = amenity.trim();
    if (trimmed.isNotEmpty && !state.amenities.contains(trimmed)) {
      emit(state.copyWith(amenities: [...state.amenities, trimmed]));
    }
  }

  void removeAmenity(String amenity) {
    final current = List<String>.from(state.amenities);
    current.remove(amenity);
    emit(state.copyWith(amenities: current));
  }
}
