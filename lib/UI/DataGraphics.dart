import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GraphicsPage extends StatefulWidget {
  @override
  _GraphicsPageState createState() => _GraphicsPageState();
}

class _GraphicsPageState extends State<GraphicsPage> {
  List<BarChartGroupData> dailyStepsData = [];
  List<BarChartGroupData> dailyConsumptionData = [];
  List<String> weekDays = [];

  @override
  void initState() {
    super.initState();
    _fetchGraphicsData();
  }

Future<void> _fetchGraphicsData() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final dailyStepsDocs = await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .collection("daily_steps")
      .orderBy("date", descending: true)
      .limit(7)
      .get();

  final dailyConsumptionDocs = await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .collection("daily_water_consumption")
      .orderBy("date", descending: true)
      .limit(7)
      .get();

  List<BarChartGroupData> steps = [];
  List<BarChartGroupData> waterConsumption = [];
  List<String> fetchedWeekDays = [];

  for (int i = 0; i < dailyStepsDocs.docs.length; i++) {
    var doc = dailyStepsDocs.docs[i];
    DateTime date = DateTime.parse(doc['date']);
    int stepsCount = int.tryParse(doc['steps'].toString()) ?? 0;

    fetchedWeekDays.add(DateFormat('EEEE').format(date));

    steps.add(
      BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: stepsCount.toDouble(),
            color: const Color.fromARGB(255, 206, 206, 206),
            width: 16,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 10000,
              color: Colors.deepPurple.withOpacity(0.3),
            ),
          )
        ],
      ),
    );
  }

  for (int i = 0; i < dailyConsumptionDocs.docs.length; i++) {
    var doc = dailyConsumptionDocs.docs[i];
    DateTime date = DateTime.parse(doc['date']);
    double consumptionAmount = double.tryParse(doc['amount'].toString()) ?? 0.0;

    waterConsumption.add(
      BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: consumptionAmount,
            color: Colors.tealAccent[200],
            width: 16,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 3000,
              color: Colors.teal.withOpacity(0.3),
            ),
          )
        ],
      ),
    );
  }

  if (!mounted) return; // Prevent setState() after dispose

  setState(() {
    dailyStepsData = steps;
    dailyConsumptionData = waterConsumption;
    weekDays = fetchedWeekDays;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E), // Slightly lighter than background
        elevation: 0,
        title: Text(
          'Health Insights',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1E1E1E),
                const Color(0xFF121212),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartSection(
                  context: context, 
                  title: 'Daily Steps',
                  subtitle: 'Your Last 7 Days of Movement',
                  chart: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10000,
                      barGroups: dailyStepsData,
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              int index = value.toInt();
                              return Text(
                                index < weekDays.length ? weekDays[index] : '', 
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 255, 255, 255),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                value.toInt().toString(), 
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                _buildChartSection(
                  context: context, 
                  title: 'Water Intake',
                  subtitle: 'Your Hydration Journey',
                  chart: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 3000,
                      barGroups: dailyConsumptionData,
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              int index = value.toInt();
                              return Text(
                                index < weekDays.length ? weekDays[index] : '', 
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 255, 255, 255),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                value.toInt().toString(), 
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection({
    required BuildContext context, 
    required String title, 
    required String subtitle, 
    required Widget chart,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }
}