//Pedometer.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fitloch/Logic/PedometerController.dart';

class PedometerScreen extends StatefulWidget {
  @override
  _PedometerScreenState createState() => _PedometerScreenState();
}

class _PedometerScreenState extends State<PedometerScreen> {
  final PedometerController _pedometerController = PedometerController();

  @override
  void initState() {
    super.initState();
    _pedometerController.initializePedometer();
    _pedometerController.stepCountNotifier.addListener(_updateUI);
    _pedometerController.stepmaxNotifier.addListener(_updateUI);
    _pedometerController.distanceGoalNotifier.addListener(_updateUI); // Listen for changes in distanceGoal
    _pedometerController.caloriesGoalNotifier.addListener(_updateUI); // Listen for changes in caloriesGoal
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pedometerController.stepCountNotifier.removeListener(_updateUI);
    _pedometerController.stepmaxNotifier.removeListener(_updateUI);
    _pedometerController.distanceGoalNotifier.removeListener(_updateUI); // Remove listener for distanceGoal
    _pedometerController.caloriesGoalNotifier.removeListener(_updateUI); // Remove listener for caloriesGoal
    _pedometerController.stopService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _pedometerController.stepCountNotifier.value;
    final stepmax = _pedometerController.stepmaxNotifier.value;
    final distanceGoal = _pedometerController.distanceGoalNotifier.value;
    final caloriesGoal = _pedometerController.caloriesGoalNotifier.value;

    // Calculate percentages for progress
    final stepsPercentage = min((steps / stepmax) * 100, 100).round();
    final calories = (steps * 0.04).round();
    final caloriesPercentage = min((calories / caloriesGoal) * 100, 100).round();
    final distance = (steps * 0.0008); // In km
    final distancePercentage = min((distance / distanceGoal) * 100, 100).round();
    final totalIndex = ((stepsPercentage + caloriesPercentage + distancePercentage) / 3).round();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Activity Tracker', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CustomProgressIndicator(
                  steps: steps,
                  calories: calories,
                  distance: distance,
                  stepsPercentage: stepsPercentage.toDouble(),
                  caloriesPercentage: caloriesPercentage.toDouble(),
                  distancePercentage: distancePercentage.toDouble(),
                  totalIndex: totalIndex,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomProgressIndicator extends StatelessWidget {
  final int steps;
  final int calories;
  final double distance;
  final double stepsPercentage;
  final double caloriesPercentage;
  final double distancePercentage;
  final int totalIndex;

  const CustomProgressIndicator({
    required this.steps,
    required this.calories,
    required this.distance,
    required this.stepsPercentage,
    required this.caloriesPercentage,
    required this.distancePercentage,
    required this.totalIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 580,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(300, 300),
            painter: CircularProgressPainter(
              stepsPercentage: stepsPercentage,
              caloriesPercentage: caloriesPercentage,
              distancePercentage: distancePercentage,
              totalIndex: totalIndex,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 400,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric(
                    icon: Icons.directions_walk,
                    value: '$steps',
                    label: 'Steps',
                    color: Color.fromARGB(255, 255, 218, 70),
                  ),
                  _buildMetric(
                    icon: Icons.local_fire_department,
                    value: '$calories',
                    label: 'kcal',
                    color: Color(0xFFFF7F50),
                  ),
                  _buildMetric(
                    icon: Icons.location_on,
                    value: distance.toStringAsFixed(1),
                    label: 'km',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double stepsPercentage;
  final double caloriesPercentage;
  final double distancePercentage;
  final int totalIndex;

  static const double startAngle = -pi / 2;
  static const double totalAngle = 3 * pi / 2;

  CircularProgressPainter({
    required this.stepsPercentage,
    required this.caloriesPercentage,
    required this.distancePercentage,
    required this.totalIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.35;
    final strokeWidth = 15.0;

    void drawArcWithPercentage(double radius, double percentage, Color color) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      paint.color = Colors.grey[900]!; // Base color
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        totalAngle,
        false,
        paint,
      );

      paint.color = color;
      final progressAngle = totalAngle * (percentage / 100);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressAngle,
        false,
        paint,
      );

      // Draw percentage text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${percentage.toInt()}%',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);

      final angle = startAngle;
      final x = center.dx + (radius * 1.0) * cos(angle) - 30;
      final y = center.dy + (radius * 1.0) * sin(angle);

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }

    drawArcWithPercentage(baseRadius + strokeWidth * 2, stepsPercentage, Color.fromARGB(255, 255, 218, 70));
    drawArcWithPercentage(baseRadius + strokeWidth * 0.8, caloriesPercentage, Color(0xFFFF7F50));
    drawArcWithPercentage(baseRadius - strokeWidth * 0.4, distancePercentage, Colors.green);

    // Total index display
    final totalIndexPainter = TextPainter(
      text: TextSpan(
        text: '$totalIndex',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    totalIndexPainter.paint(
        canvas, Offset(center.dx - totalIndexPainter.width / 2, center.dy - totalIndexPainter.height / 2));

    final totalIndexLabelPainter = TextPainter(
      text: TextSpan(
        text: 'Total index',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[400],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    totalIndexLabelPainter.paint(
        canvas, Offset(center.dx - totalIndexLabelPainter.width / 2, center.dy + totalIndexPainter.height / 2 + 5));
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) =>
      stepsPercentage != oldDelegate.stepsPercentage ||
      caloriesPercentage != oldDelegate.caloriesPercentage ||
      distancePercentage != oldDelegate.distancePercentage;
}
