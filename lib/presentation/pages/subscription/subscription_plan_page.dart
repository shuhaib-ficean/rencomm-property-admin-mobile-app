import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/routes/app_routes.dart';

class SubscriptionPlanPage extends StatefulWidget {
  const SubscriptionPlanPage({super.key});

  @override
  State<SubscriptionPlanPage> createState() => _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends State<SubscriptionPlanPage> {
  String? _selectedPlan;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'basic',
      'name': 'Basic Plan',
      'price': 'QR 100 / month',
      'features': [
        'Up to 5 Properties',
        'Basic Dashboard Analytics',
        'Email Support',
      ],
    },
    {
      'id': 'pro',
      'name': 'Pro Plan',
      'price': 'QR 250 / month',
      'features': [
        'Up to 20 Properties',
        'Advanced Analytics & Charts',
        'Priority Support',
        'Tenant Management',
      ],
    },
    {
      'id': 'enterprise',
      'name': 'Enterprise Plan',
      'price': 'QR 500 / month',
      'features': [
        'Unlimited Properties',
        'Full Suite Access',
        '24/7 Dedicated Support',
        'Custom Reporting',
      ],
    },
  ];

  void _handleProceed() {
    if (_selectedPlan != null) {
      final planDetails = _plans.firstWhere((p) => p['id'] == _selectedPlan);
      Navigator.pushNamed(
        context,
        AppRoutes.subscriptionDetails,
        arguments: planDetails,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan to proceed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Select Subscription',
            style: GoogleFonts.montserrat(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  final isSelected = _selectedPlan == plan['id'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPlan = plan['id'];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                plan['name'],
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle,
                                    color: Theme.of(context).primaryColor),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan['price'],
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(
                            (plan['features'] as List).length,
                            (fIndex) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.check,
                                      size: 16, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    plan['features'][fIndex],
                                    style: GoogleFonts.montserrat(
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Proceed',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
