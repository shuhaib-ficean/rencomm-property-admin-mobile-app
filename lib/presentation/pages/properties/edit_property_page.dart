import 'package:flutter/material.dart';
import '../../../core/models/property_model.dart';
import 'add_property_page.dart';

class EditPropertyPage extends StatelessWidget {
  final PropertyModel property;
  
  const EditPropertyPage({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return AddPropertyPage(property: property);
  }
}

