import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'GenderSelector.dart';

class BloodTypeSelectorPage extends StatefulWidget {
  @override
  _BloodTypeSelectorPageState createState() => _BloodTypeSelectorPageState();
}

class _BloodTypeSelectorPageState extends State<BloodTypeSelectorPage> {
  String selectedBloodType = 'A';
  String selectedRhFactor = '+';
  String selectedBloodGroup = 'A +'; // Stores the combined blood type
  final List<String> bloodTypes = ['A', 'B', 'O', 'AB'];
  final ScrollController _scrollController = ScrollController();

  // Method to save the blood type to Firestore
  Future<void> saveBloodTypeToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Medical data')
          .doc('Blood')
          .set({'Blood Type': selectedBloodGroup});
    }
  }


  void _onBloodTypeSelected(String type) {
    setState(() {
      selectedBloodType = type;
      selectedBloodGroup = '$selectedBloodType$selectedRhFactor';
    });
  }

  void _onRhFactorSelected(String factor) {
    setState(() {
      selectedRhFactor = factor;
      selectedBloodGroup = '$selectedBloodType$selectedRhFactor';
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
                          '5 of 11',
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
                        "What's your blood type?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Blood type selection
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: bloodTypes.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 4 : 2,
                                  right: index == bloodTypes.length - 1 ? 4 : 2,
                                ),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () => _onBloodTypeSelected(bloodTypes[index]),
                                    child: Container(
                                      width: 73,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: selectedBloodType == bloodTypes[index]
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          bloodTypes[index],
                                          style: TextStyle(
                                            color: selectedBloodType == bloodTypes[index]
                                                ? const Color(0xFFFF4365)
                                                : Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Display selected blood type
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              selectedBloodType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 120,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // RH factor selection
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => _onRhFactorSelected('+'),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: selectedRhFactor == '+'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '+',
                                        style: TextStyle(
                                          color: selectedRhFactor == '+'
                                              ? const Color(0xFFFF4365)
                                              : Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Or',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () => _onRhFactorSelected('-'),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: selectedRhFactor == '-'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '-',
                                        style: TextStyle(
                                          color: selectedRhFactor == '-'
                                              ? const Color(0xFFFF4365)
                                              : Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                  onPressed: () async {
                    // Save the selected blood group to Firestore
                    await saveBloodTypeToFirestore();

                    // Proceed to the next screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenderSelectorPage(),
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
