import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Pedometer.dart';
import 'package:intl/intl.dart';
import 'WaterConsumption.dart';
import 'ProfileScreen.dart';
import 'package:fitloch/Logic/PedometerController.dart';
import 'DataGraphics.dart';

class ReadingProgressScreen extends StatelessWidget {
  const ReadingProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (currentUser != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildProfileIcon(context, null);
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildProfileIcon(context, null, isLoading: true);
                        }

                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        final String? photoUrl = data?['googleData']?['photoUrl'];

                        return _buildProfileIcon(context, photoUrl);
                      },
                    )
                  else
                    _buildProfileIcon(context, null),
                ],
              ),
              const SizedBox(height: 20),

              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser?.uid)
                    .collection('daily_steps')
                    .doc(todayDate)
                    .snapshots(),
                builder: (context, snapshot) {
                  int steps = 0;
                  double distance_km = 0.0;

                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;

                    if (data != null) {
                      steps = (data['steps'] ?? 0).toInt();
                      distance_km = (data['distance_km'] ?? 0).toDouble();
                    }
                  }

                  return Container(
                    width: double.infinity,
                    height: 175,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 218, 70),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PROGRESS',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                const Icon(Icons.directions_run, size: 36, color: Colors.black),
                                const SizedBox(width: 8),
                                Text(
                                  '$steps',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(
                                        'out of ${PedometerController().stepmaxNotifier.value}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black.withOpacity(0.7),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(
                                        'is about ${distance_km.toStringAsFixed(2)} km',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black.withOpacity(0.7),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Steps progress bar
                            ValueListenableBuilder<int>(
                              valueListenable: PedometerController().stepmaxNotifier,
                              builder: (context, stepmax, _) {
                                return Container(
                                  width: double.infinity,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: steps / stepmax,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PedometerScreen()),
                              );
                            },
                            child: const CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.black,
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Row(
  children: [
    Expanded(
      child: Stack(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7F50),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GRAPHICS',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.bar_chart,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GraphicsPage()),
                );
              },
              child: const CircleAvatar(
                radius: 15,
                backgroundColor: Colors.black,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(width: 16),

    Expanded(
      child: Stack(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 109, 211, 255),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: Colors.black,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'WATER INTAKE',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser?.uid ?? '')
                      .collection('daily_water_consumption')
                      .doc(todayDate)
                      .snapshots(),
                  builder: (context, snapshot) {
                    double amount = 0;
                    if (snapshot.hasData && snapshot.data != null) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        amount = (data['amount'] ?? 0).toDouble();
                      }
                    }
                    return Text(
                      '${amount.toInt()} ml',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlcoholAssessmentPage(userId: currentUser?.uid ?? '')),
                );
              },
              child: const CircleAvatar(
                radius: 15,
                backgroundColor: Colors.black,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    ),

    const SizedBox(width: 16),
  ],
),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon(BuildContext context, String? photoUrl, {bool isLoading = false}) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () {
        if (currentUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProfilePage(profileUid: currentUser.uid)),
          );
        }
      },
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : (photoUrl == null ? const Icon(Icons.person, color: Colors.white) : null),
      ),
    );
  }
}