part of 'add_property_cubit.dart';

class AddPropertyState extends Equatable {
  final int currentStep;
  final String name;
  final String selectedType;
  final String description;
  final String address;
  final String lat;
  final String long;
  final String country;
  final String stateText;
  final String city;
  final String pincode;
  final String currency;
  final List<XFile> images;
  
  final int numFloors;
  final int unitsPerFloor;
  final List<Map<String, dynamic>> buildingFloors;
  
  final List<Map<String, dynamic>> propertyExpenses;
  
  final String? managerName;
  final String? managerPhone;
  final String? managerEmail;

  final List<String> availableRoomTypes;
  final List<String> amenities;

  final String? errorMessage;

  const AddPropertyState({
    this.currentStep = 1,
    this.name = '',
    this.selectedType = AppConstants.propertyTypeFlat,
    this.description = '',
    this.address = '',
    this.lat = '',
    this.long = '',
    this.country = '',
    this.stateText = '',
    this.city = '',
    this.pincode = '',
    this.currency = 'QAR',
    this.images = const [],
    this.numFloors = 1,
    this.unitsPerFloor = 1,
    this.buildingFloors = const [],
    this.propertyExpenses = const [],
    this.managerName,
    this.managerPhone,
    this.managerEmail,
    this.availableRoomTypes = const [
      '1 BHK',
      '2 BHK',
      '3 BHK',
      'Studio',
      'Master Bedroom',
      'Standard',
    ],
    this.amenities = const [],
    this.errorMessage,
  });

  AddPropertyState copyWith({
    int? currentStep,
    String? name,
    String? selectedType,
    String? description,
    String? address,
    String? lat,
    String? long,
    String? country,
    String? stateText,
    String? city,
    String? pincode,
    String? currency,
    List<XFile>? images,
    int? numFloors,
    int? unitsPerFloor,
    List<Map<String, dynamic>>? buildingFloors,
    List<Map<String, dynamic>>? propertyExpenses,
    String? managerName,
    String? managerPhone,
    String? managerEmail,
    List<String>? availableRoomTypes,
    List<String>? amenities,
    String? errorMessage,
  }) {
    return AddPropertyState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      selectedType: selectedType ?? this.selectedType,
      description: description ?? this.description,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      country: country ?? this.country,
      stateText: stateText ?? this.stateText,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      currency: currency ?? this.currency,
      images: images ?? this.images,
      numFloors: numFloors ?? this.numFloors,
      unitsPerFloor: unitsPerFloor ?? this.unitsPerFloor,
      buildingFloors: buildingFloors ?? this.buildingFloors,
      propertyExpenses: propertyExpenses ?? this.propertyExpenses,
      managerName: managerName ?? this.managerName,
      managerPhone: managerPhone ?? this.managerPhone,
      managerEmail: managerEmail ?? this.managerEmail,
      availableRoomTypes: availableRoomTypes ?? this.availableRoomTypes,
      amenities: amenities ?? this.amenities,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentStep, name, selectedType, description, address, lat, long, country, stateText, city, pincode, currency, images,
        numFloors, unitsPerFloor, buildingFloors, propertyExpenses, managerName, managerPhone, managerEmail, availableRoomTypes, amenities, errorMessage,
      ];
}
