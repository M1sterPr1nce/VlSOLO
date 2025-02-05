//WaterConsumption.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class AlcoholAssessmentPage extends StatefulWidget {
  final String userId;
  final int currentQuestion;
  final int totalQuestions;
  final int selectedLevel;

  const AlcoholAssessmentPage({
    Key? key,
    required this.userId,
    this.currentQuestion = 9,
    this.totalQuestions = 11,
    this.selectedLevel = 3,
  }) : super(key: key);

  @override
  State<AlcoholAssessmentPage> createState() => _AlcoholAssessmentPageState();
}

class _AlcoholAssessmentPageState extends State<AlcoholAssessmentPage> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _yAnimations;
  late List<Animation<double>> _xAnimations;
  final TextEditingController _inputController = TextEditingController();
  double _waterLevel = 0.0; 
  bool _isKeyboardVisible = false;
  double? _maxWaterAmount; 
  FocusNode _focusNode = FocusNode();

final List<BubbleData> bubbles = [
  BubbleData(30, 320, 8),  
  BubbleData(50, 300, 10),
  BubbleData(40, 280, 6),
  BubbleData(70, 270, 12),
  BubbleData(55, 320, 8),
  BubbleData(80, 340, 6),
  BubbleData(45, 290, 11),
  BubbleData(75, 310, 13),
  BubbleData(60, 330, 4),
  BubbleData(65, 350, 5),

    BubbleData(30, 240, 8), 
  BubbleData(50, 220, 10),
  BubbleData(40, 200, 6),
  BubbleData(70, 190, 12),
  BubbleData(55, 240, 8),
  BubbleData(80, 260, 6),
  BubbleData(45, 210, 11),
  BubbleData(75, 230, 13),
  BubbleData(60, 250, 4),
  BubbleData(65, 270, 5),

      BubbleData(30, 200, 8), 
  BubbleData(50, 180, 10),
  BubbleData(40, 160, 6),
  BubbleData(70, 150, 12),
  BubbleData(55, 200, 8),
  BubbleData(80, 220, 6),
  BubbleData(45, 170, 11),
  BubbleData(75, 190, 13),
  BubbleData(60, 210, 4),
  BubbleData(65, 230, 5),
];

  @override
void initState() {
  super.initState();
  _controllers = [];
  _yAnimations = [];
  _xAnimations = [];

  final random = math.Random();

  for (var i = 0; i < bubbles.length; i++) {
    final controller = AnimationController(
      duration: Duration(milliseconds: 2000 + random.nextInt(2000)),
      vsync: this,
    );

    final yAnimation = Tween<double>(begin: bubbles[i].y, end: bubbles[i].y - 30.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    final xAnimation = Tween<double>(
      begin: bubbles[i].x,
      end: bubbles[i].x + (random.nextBool() ? 5 : -5),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    _controllers.add(controller);
    _yAnimations.add(yAnimation);
    _xAnimations.add(xAnimation);

    controller.repeat(reverse: true);
  }

  _focusNode.addListener(() {
  if (!_focusNode.hasFocus) {
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _isKeyboardVisible = false;
      });
    });
  } else {
    setState(() {
      _isKeyboardVisible = true;
    });
  }
});


  _fetchUserWaterData().then((_) {
    _loadStoredWaterData();
  });
}


Future<void> _fetchUserWaterData() async {
  try {
    DocumentSnapshot weightDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('Medical data')
        .doc('weight')
        .get();

    if (weightDoc.exists) {
      double weight = (weightDoc.data() as Map<String, dynamic>)['weight'] ?? 0;
      String unit = (weightDoc.data() as Map<String, dynamic>)['unit'] ?? 'kg';

      if (unit == 'kg') {
        _maxWaterAmount = weight * 30;
      } else if (unit == 'lbs') {
        _maxWaterAmount = weight * 0.67; 
      }

      setState(() {});
    }
  } catch (e) {
    print("Error fetching user data: $e");
    setState(() {
      _maxWaterAmount = 2000; 
    });
  }

  }

Future<void> _loadStoredWaterData() async {
  try {
    var now = DateTime.now();
    String dateString = now.toIso8601String().split('T')[0];

    var dailyWaterRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('daily_water_consumption')
        .doc(dateString);

    var docSnapshot = await dailyWaterRef.get();

    if (docSnapshot.exists && _maxWaterAmount != null && _maxWaterAmount! > 0) {
      double amount = (docSnapshot.data()?['amount'] ?? 0).toDouble();
      setState(() {
        _waterLevel = (amount / _maxWaterAmount!).clamp(0.0, 1.0);

        print("Fetched water amount: ${docSnapshot.data()?['amount']}");
        print("Max water amount: $_maxWaterAmount");

      });
    } else {
      setState(() {
        _waterLevel = 0.0;
      });
    }
  } catch (e) {
    print("Error loading water data: $e");
  }
}



Future<void> _storeWaterData(double amount) async {
  try {
    var now = DateTime.now();
    String dateString = now.toIso8601String().split('T')[0];

    var dailyWaterRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('daily_water_consumption')
        .doc(dateString);

    await dailyWaterRef.set({
      'amount': amount,
      'timestamp': now,
    }, SetOptions(merge: true));
  } catch (e) {
    print("Error saving water data: $e");
  }
}


  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateWaterLevel() async {
  if (_maxWaterAmount == null) return;
  final value = double.tryParse(_inputController.text) ?? 0;

  var now = DateTime.now();
  String dateString = now.toIso8601String().split('T')[0];

  var dailyWaterRef = FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId)
      .collection('daily_water_consumption')
      .doc(dateString);

  var docSnapshot = await dailyWaterRef.get();
  double currentAmount = 0;

  if (docSnapshot.exists) {
    currentAmount = (docSnapshot.data()?['amount'] ?? 0).toDouble();
  }

  double newAmount = currentAmount + value;

  await dailyWaterRef.set({
    'amount': newAmount,
    'timestamp': now,
    'date': dateString,
  }, SetOptions(merge: true));

  setState(() {
    _waterLevel = (newAmount / _maxWaterAmount!).clamp(0.0, 1.0);
  });
}


  Future<void> _saveDailyWaterConsumption(double amount) async {
  try {
    var userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    var now = DateTime.now();
    String dateString = now.toIso8601String().split('T')[0];
    String today = DateTime.now().toIso8601String().substring(0, 10);
    
    var dailyWaterRef = userRef.collection('daily_water_consumption').doc(dateString);
    
    var docSnapshot = await dailyWaterRef.get();
    
    if (docSnapshot.exists) {
      await dailyWaterRef.update({
        'amount': FieldValue.increment(amount), 
        'date': today,
      });
    } else {
      await dailyWaterRef.set({
        'amount': amount,
        'date': today,
      });
    }
  } catch (e) {
    print("Error saving daily water consumption: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    if (_maxWaterAmount == null) {
      return Center(child: CircularProgressIndicator());
    }

    final currentWaterAmount = (_waterLevel * _maxWaterAmount!).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFF8A4EFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Assessment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Water Consumption',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$currentWaterAmount ml / ${_maxWaterAmount!.toInt()} ml',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SvgPicture.string(
                        '''<svg width="140" height="400" viewBox="0 0 140 420" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M55 5 H85 C88 5 95 8 95 15 V25 C95 30 88 35 85 35 H55 C52 35 45 30 45 25 V15 C45 8 52 5 55 5 Z" fill="black" fill-opacity="0.2"/>
                          <path fill-rule="evenodd" clip-rule="evenodd" d="M50 30 H90 V90 C90 100 100 110 105 120 C110 130 120 150 120 180 V370 C120 390 105 405 85 410 H55 C35 405 20 390 20 370 V180 C20 150 30 130 35 120 C40 110 50 100 50 90 V30Z" fill="black" fill-opacity="0.2"/>
                        </svg>''',
                        width: 120,
                        height: 380,
                      ),
                        if (true)
                          Positioned(
                            bottom: 380 * _waterLevel - 2,
                            left: 10,
                            right: 10,
                            child: CustomPaint(
                              size: Size(120, 2),
                              painter: WaterLevelPainter(_waterLevel),
                            ),
                          ),
                      ...List.generate(bubbles.length, (index) {
                        return AnimatedBuilder(
                          animation: _controllers[index],
                          builder: (context, child) {
                            final newY = _yAnimations[index].value;
                              if (newY < (380 * (1 - _waterLevel))) {
                                return SizedBox();
                              }
                            return Positioned(
                              left: _xAnimations[index].value,
                              top: newY,
                              child: Container(
                                width: bubbles[index].size.toDouble(),
                                height: bubbles[index].size.toDouble(),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        border: InputBorder.none,
                        hintText: 'Enter value (ml)',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                      keyboardType: TextInputType.number,
                      onTap: () => _focusNode.requestFocus(),
                      onEditingComplete: () {
                        _focusNode.unfocus();
                        setState(() {
                          _isKeyboardVisible = false; 
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_upward, color: Colors.black),
                      onPressed: _updateWaterLevel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaterLevelPainter extends CustomPainter {
  final double waterLevel;

  WaterLevelPainter(this.waterLevel);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 177, 177, 177)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height * waterLevel),
      Offset(size.width, size.height * waterLevel),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class BubbleData {
  final double x;
  final double y;
  final int size;

  BubbleData(this.x, this.y, this.size);
}
