import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'package:fitloch/Logic/PedometerController.dart';
import 'package:fitloch/UI/SignIn.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final pedometer = PedometerController();
  await pedometer.initializePedometer();

  // Инициализация WorkManager
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  // Регистрация периодической задачи
  Workmanager().registerPeriodicTask(
    "step_counter_task",
    "count_steps",
    frequency: Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: false,
      requiresCharging: false,
    ),
  );

  runApp(MyApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final pedometer = PedometerController();
    await pedometer.initializePedometer();
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignInPage(),
    );
  }
}