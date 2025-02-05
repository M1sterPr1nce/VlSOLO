import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'HomePage.dart';

class GenderSelectorPage extends StatefulWidget {
  @override
  _GenderSelectorPageState createState() => _GenderSelectorPageState();
}

class _GenderSelectorPageState extends State<GenderSelectorPage> {
  String selectedGender = 'Male';
  final List<String> genderOptions = ['Male', 'Female'];
  final ScrollController _scrollController = ScrollController();

  // Fetch user medical data from Firestore
  Future<Map<String, dynamic>> getMedicalData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String userId = user.uid;

    // Fetch height
    DocumentSnapshot heightDoc = await firestore.collection('users').doc(userId).collection('Medical data').doc('height').get();
    double? height = heightDoc.exists ? (heightDoc['height'] as num?)?.toDouble() : null;
    String? heightUnit = heightDoc.exists ? (heightDoc['unit'] as String?) : 'cm';

    // Fetch weight
    DocumentSnapshot weightDoc = await firestore.collection('users').doc(userId).collection('Medical data').doc('weight').get();
    double? weight = weightDoc.exists ? (weightDoc['weight'] as num?)?.toDouble() : null;
    String? weightUnit = weightDoc.exists ? (weightDoc['unit'] as String?) : 'kg';

    // Fetch gender
    DocumentSnapshot genderDoc = await firestore.collection('users').doc(userId).collection('Medical data').doc('Gender').get();
    String? gender = genderDoc.exists ? (genderDoc['Gender'] as String?) : null;

    // Fetch age
    DocumentSnapshot ageDoc = await firestore.collection('users').doc(userId).collection('Medical data').doc('Age').get();
    int? age = ageDoc.exists ? (ageDoc['age'] as num?)?.toInt() : null;

    return {
      'height': height,
      'heightUnit': heightUnit,
      'weight': weight,
      'weightUnit': weightUnit,
      'gender': gender,
      'age': age,
    };
  }

  // Convert lbs to kg if needed
  double convertWeightToKg(double weight, String unit) {
    if (unit == 'lbs') {
      return weight * 0.453592; // 1 lb = 0.453592 kg
    }
    return weight;
  }

  // Simplified BMI calculation for adults
  Map<String, dynamic> calculateBMI(double? height, double? weight, String? weightUnit) {
    if (height == null || weight == null || height <= 0) return {'bmi': null, 'category': 'Invalid data'};

    double weightInKg = convertWeightToKg(weight, weightUnit ?? 'kg');
    double heightInMeters = height / 100; // Convert cm to meters

    double bmi = weightInKg / (heightInMeters * heightInMeters);

    // Get BMI category for adults
    String category = _getBMICategory(bmi);

    return {
      'bmi': bmi,
      'category': category,
    };
  }

  // Get BMI category for adults (no age adjustment)
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 24.9) {
      return 'Normal weight';
    } else if (bmi < 29.9) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  // Save gender, BMI, and interpretation to Firestore
  Future<void> saveDataToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String userId = user.uid;

    // Save gender
    await firestore.collection('users').doc(userId).collection('Medical data').doc('Gender').set({'Gender': selectedGender});

    // Fetch existing medical data
    Map<String, dynamic> medicalData = await getMedicalData();

    double? height = medicalData['height'];
    String? heightUnit = medicalData['heightUnit'];
    double? weight = medicalData['weight'];
    String? weightUnit = medicalData['weightUnit'];

    // Calculate BMI and its category
    Map<String, dynamic> bmiData = calculateBMI(height, weight, weightUnit);
    double? bmi = bmiData['bmi'];
    String category = bmiData['category'];

    // Save BMI and category to Firestore
    if (bmi != null) {
      await firestore.collection('users').doc(userId).collection('Medical data').doc('BMI').set({
        'bmi': bmi,
        'category': category,
      });
    }
  }

  void _onGenderSelected(String gender) {
    setState(() {
      selectedGender = gender;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF4365),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button and title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Assessment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '3 of 11',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // Question text
                      const Text(
                        "What's your gender?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Gender selection
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: genderOptions.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _onGenderSelected(genderOptions[index]),
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                width: 150,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: selectedGender == genderOptions[index]
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    genderOptions[index],
                                    style: TextStyle(
                                      color: selectedGender == genderOptions[index]
                                          ? const Color(0xFFFF4365)
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Display selected gender with icon
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selectedGender == 'Male'
                                  ? Icons.male
                                  : selectedGender == 'Female'
                                      ? Icons.female
                                      : Icons.transgender,
                              size: 160,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              selectedGender,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Continue button
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    saveDataToFirestore();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReadingProgressScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Color(0xFFFF4365),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
