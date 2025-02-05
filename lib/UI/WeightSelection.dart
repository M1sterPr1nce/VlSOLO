import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'HeightSelection.dart';

class WeightSelectionPage extends StatefulWidget {
  const WeightSelectionPage({super.key});

  @override
  State<WeightSelectionPage> createState() => _WeightSelectionPageState();
}

class _WeightSelectionPageState extends State<WeightSelectionPage> {
  double weightKg = 65.0;
  bool isKg = true;
  final ScrollController _scrollController = ScrollController();
  static const double minWeight = 30.0;
  static const double maxWeight = 200.0;
  static const double pixelsPerKg = 10.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialOffset = (maxWeight - weightKg) * pixelsPerKg;
      _scrollController.jumpTo(initialOffset);
    });
  }

  double get weightLbs => weightKg * 2.20462;

  Future<void> _saveWeightToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Medical data')
          .doc('weight')
          .set({'weight': weightKg, 'unit': isKg ? 'kg' : 'lbs'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF151515), Color(0xFF151515)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Assessment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Question
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  "What's your current\nweight right now?",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),

              // Unit Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUnitButton('kg', true),
                    const SizedBox(width: 16),
                    _buildUnitButton('lbs', false),
                  ],
                ),
              ),

              // Weight Display
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: Text(
                    isKg ? '${weightKg.toStringAsFixed(1)} kg' : '${weightLbs.toStringAsFixed(1)} lbs',
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Custom Sliding Scale
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo is ScrollUpdateNotification) {
                          setState(() {
                            double newWeight = maxWeight - (scrollInfo.metrics.pixels / pixelsPerKg);
                            weightKg = newWeight.clamp(minWeight, maxWeight);
                          });
                        }
                        return true;
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Container(
                          width: (maxWeight - minWeight) * pixelsPerKg,
                          height: 100,
                          child: CustomPaint(
                            painter: ScalePainter(),
                            size: Size((maxWeight - minWeight) * pixelsPerKg, 100),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveWeightToFirestore(); // Save data
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HeightSelection()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF151515),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20, color: Color(0xFF151515)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitButton(String unit, bool isKgUnit) {
    final isSelected = isKg == isKgUnit;
    return GestureDetector(
      onTap: () {
        setState(() {
          isKg = isKgUnit;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xFF151515) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class ScalePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    double totalKg = 170;
    for (int i = 0; i <= totalKg; i++) {
      double x = i * 10.0;
      double height = i % 5 == 0 ? 20.0 : 10.0;

      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        paint,
      );

      if (i % 5 == 0) {
        textPainter.text = TextSpan(
          text: '${200 - i}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height / 2 + height / 2 + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
