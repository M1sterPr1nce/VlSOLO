import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'WeightSelection.dart'; // Ensure this file exists

class AgeSelectionPage extends StatelessWidget {
  const AgeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AgeSelector();
  }
}

class AgeSelector extends StatefulWidget {
  const AgeSelector({super.key});

  @override
  State<AgeSelector> createState() => _AgeSelectorState();
}

class _AgeSelectorState extends State<AgeSelector> {
  final FixedExtentScrollController _scrollController = FixedExtentScrollController(initialItem: 18);
  final double itemHeight = 65.0;
  int selectedAge = 19;
  final int minAge = 13;
  final int maxAge = 75;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Function to save age to Firestore
  Future<void> saveAgeToFirestore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("Medical data")
            .doc("Age")
            .set({"age": selectedAge});
        print("Age saved successfully!");
      } else {
        print("No user logged in.");
      }
    } catch (e) {
      print("Error saving age: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'Assessment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Question
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "What's your Age?",
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 60),
            // Age Selector
            Expanded(
              child: Center(
                child: SizedBox(
                  height: itemHeight * 5,
                  child: Stack(
                    children: [
                      // Selection highlight
                      Center(
                        child: Container(
                          height: itemHeight,
                          width: 120,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 21, 21, 21),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      // Age list
                      ListWheelScrollView.useDelegate(
                        controller: _scrollController,
                        itemExtent: itemHeight,
                        perspective: 0.005,
                        diameterRatio: 2.5,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            selectedAge = index + 1;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: maxAge,
                          builder: (context, index) {
                            final age = index + 1;
                            return Container(
                              height: itemHeight,
                              alignment: Alignment.center,
                              child: Text(
                                age.toString(),
                                style: TextStyle(
                                  fontSize: age == selectedAge ? 40 : 32,
                                  fontWeight: age == selectedAge ? FontWeight.w600 : FontWeight.w400,
                                  color: age == selectedAge ? Colors.white : Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () async {
                  await saveAgeToFirestore();
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WeightSelectionPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
