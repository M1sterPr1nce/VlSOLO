import 'package:flutter/material.dart';
import 'package:fitloch/Logic/PedometerController.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PedometerController().initializePedometer();
  runApp(MyTestApp());
}

class MyTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pedometer = PedometerController();

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Pedometer Test')),
        body: ValueListenableBuilder<int>(
          valueListenable: pedometer.stepCountNotifier,
          builder: (context, steps, _) {
            return Center(
              child: Text('Steps: $steps', style: TextStyle(fontSize: 24)),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => pedometer.resetSteps(),
          child: Icon(Icons.refresh),
        ),
      ),
    );
  }
}
