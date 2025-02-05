//PedometerController.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PedometerController {
  static final PedometerController _instance = PedometerController._internal();
  factory PedometerController() => _instance;
  PedometerController._internal();

  ValueNotifier<int> stepCountNotifier = ValueNotifier<int>(0);
  ValueNotifier<int> stepmaxNotifier = ValueNotifier<int>(10000); // Default stepmax
  ValueNotifier<double> distanceGoalNotifier = ValueNotifier<double>(8.0); // Default distance goal in km
  ValueNotifier<int> caloriesGoalNotifier = ValueNotifier<int>(500); // Default calories goal

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  Timer? _backgroundTimer;

  /// Initialize pedometer
  Future<void> initializePedometer() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _resetStepsIfNewDay();
    await _loadSavedSteps();
    await fetchAndSetStepMax(); // Fetch and update stepmax, distance goal, and calories goal
    _startStepCounting();
  }

  /// Fetch BMI and update stepmax, distance goal, and calories goal
  Future<void> fetchAndSetStepMax() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final bmiDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("Medical data")
          .doc("BMI")
          .get();

      double bmi = bmiDoc.exists ? (bmiDoc.data()?["bmi"] as num).toDouble() : 22.0; // Default BMI

      int stepmax;
      double distanceGoal;
      int caloriesGoal;

      if (bmi < 18.5) {
        stepmax = 12000;
        distanceGoal = 10.0; // 10 km
        caloriesGoal = 600;  // 600 calories
      } else if (bmi >= 18.5 && bmi < 25) {
        stepmax = 25000;
        distanceGoal = 20.0;  // 8 km
        caloriesGoal = 700;  // 500 calories
      } else if (bmi >= 25 && bmi < 30) {
        stepmax = 8000;
        distanceGoal = 6.0;  // 6 km
        caloriesGoal = 400;  // 400 calories
      } else {
        stepmax = 6000;
        distanceGoal = 5.0;  // 5 km
        caloriesGoal = 350;  // 350 calories
      }

      // Update the values
      stepmaxNotifier.value = stepmax; // Notify UI of stepmax update
      distanceGoalNotifier.value = distanceGoal; // Notify UI of distance goal update
      caloriesGoalNotifier.value = caloriesGoal; // Notify UI of calories goal update

      print("Stepmax updated: $stepmax, Distance goal: $distanceGoal km, Calories goal: $caloriesGoal cal");
    } catch (e) {
      print("Error fetching stepmax, distance goal, and calories goal: $e");
    }
  }

  /// Load saved steps from Firestore
  Future<void> _loadSavedSteps() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String today = DateTime.now().toIso8601String().substring(0, 10);
      final stepDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("daily_steps")
          .doc(today)
          .get();

      if (stepDoc.exists) {
        stepCountNotifier.value = stepDoc.data()?["steps"] ?? 0;
      } else {
        stepCountNotifier.value = 0;
      }
      print("Loaded steps: ${stepCountNotifier.value}");
    } catch (e) {
      print("Error loading steps from Firestore: $e");
    }
  }

  /// Start step counting
  void _startStepCounting() {
    _accelerometerSubscription = userAccelerometerEvents.listen((event) async {
      double magnitude = (event.x * event.x) + (event.y * event.y) + (event.z * event.z);

      if (magnitude > 10) { 
        stepCountNotifier.value++;
        await _saveStepsToFirestore();
        print("Step detected! Total steps: ${stepCountNotifier.value}");
      }
    }, onError: (error) {
      print("Error with accelerometer: $error");
    });

    // Save steps periodically
    _backgroundTimer = Timer.periodic(Duration(minutes: 15), (timer) async {
      await _saveStepsToFirestore();
      print("Steps saved in background: ${stepCountNotifier.value}");
    });
  }

  /// Reset steps if a new day has started
  Future<void> _resetStepsIfNewDay() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String today = DateTime.now().toIso8601String().substring(0, 10);
      final stepDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("daily_steps")
          .doc(today)
          .get();

      if (!stepDoc.exists) {
        // New day, reset steps in Firestore
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("daily_steps")
            .doc(today)
            .set({
          "steps": 0,
          "date": today,
        });
        stepCountNotifier.value = 0;
        print("New day detected, resetting steps in Firestore.");
      }
    } catch (e) {
      print("Error resetting steps in Firestore: $e");
    }
  }

  /// Save steps and related data to Firestore
  Future<void> _saveStepsToFirestore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String today = DateTime.now().toIso8601String().substring(0, 10);
      int steps = stepCountNotifier.value;
      int stepmax = stepmaxNotifier.value; // Use the stored stepmax
      double distanceGoal = distanceGoalNotifier.value; // Use the stored distance goal
      int caloriesGoal = caloriesGoalNotifier.value; // Use the stored calories goal

      final stepsPercentage = min((steps / stepmax) * 100, 100).round();
      final caloriesBurned = (steps * 0.04).round();
      final caloriesPercentage = min((caloriesBurned / caloriesGoal) * 100, 100).round();
      final distanceKm = (steps * 0.0008).toDouble();
      final distancePercentage = min((distanceKm / distanceGoal) * 100, 100).round();
      final totalIndex = ((stepsPercentage + caloriesPercentage + distancePercentage) / 3).round();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("daily_steps")
          .doc(today)
          .set({
        "date": today,
        "steps": steps,
        "distance_km": distanceKm,
        "calories_burned": caloriesBurned,
        "total_index": totalIndex,
        "stepmax": stepmax, // Store stepmax
        "distance_goal": distanceGoal, // Store distance goal
        "calories_goal": caloriesGoal, // Store calories goal
      }, SetOptions(merge: true));

      print("Steps saved with stepmax: $stepmax, Distance goal: $distanceGoal, Calories goal: $caloriesGoal");
    } catch (e) {
      print("Error saving steps to Firestore: $e");
    }
  }

  /// Reset steps manually
  Future<void> resetSteps() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String today = DateTime.now().toIso8601String().substring(0, 10);
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("daily_steps")
          .doc(today)
          .set({
        "steps": 0,
        "date": today,
      });

      stepCountNotifier.value = 0;
      print("Steps reset to 0 in Firestore");
    } catch (e) {
      print("Error resetting steps in Firestore: $e");
    }
  }

  /// Stop service
  Future<void> stopService() async {
    _accelerometerSubscription?.cancel();
    _backgroundTimer?.cancel();
    print("Background service stopped");
  }
}
