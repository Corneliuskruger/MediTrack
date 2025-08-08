import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedSymptom;
  int _timeframe = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('symptoms')
                  .where('createdBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final symptoms = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedSymptom,
                  hint: const Text('Select a Symptom'),
                  onChanged: (value) {
                    setState(() {
                      _selectedSymptom = value;
                    });
                  },
                  items: symptoms.map((symptom) {
                    return DropdownMenuItem<String>(
                      value: symptom.id,
                      child: Text(symptom['name']),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _timeframe,
              hint: const Text('Select Timeframe'),
              onChanged: (value) {
                setState(() {
                  _timeframe = value!;
                });
              },
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 Day')),
                DropdownMenuItem(value: 2, child: Text('2 Days')),
                DropdownMenuItem(value: 3, child: Text('3 Days')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedSymptom != null
                  ? _buildChart()
                  : const Center(child: Text('Please select a symptom and timeframe.')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in.'));
    }

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: _timeframe));

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('logEntries')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'symptom')
          .where('itemId', isEqualTo: _selectedSymptom)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get(),
      builder: (context, symptomSnapshot) {
        if (!symptomSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('logEntries')
              .where('userId', isEqualTo: user.uid)
              .where('type', isEqualTo: 'supplement')
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
              .get(),
          builder: (context, supplementSnapshot) {
            if (!supplementSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final supplementLogs = supplementSnapshot.data!.docs;
            final supplementFrequency = <String, int>{};

            for (var log in supplementLogs) {
              final supplementId = log['itemId'];
              supplementFrequency[supplementId] = (supplementFrequency[supplementId] ?? 0) + 1;
            }

            return BarChart(
              BarChartData(
                barGroups: supplementFrequency.entries.map((entry) {
                  return BarChartGroupData(
                    x: supplementFrequency.keys.toList().indexOf(entry.key),
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < supplementFrequency.keys.length) {
                          final supplementId = supplementFrequency.keys.toList()[index];
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('supplements').doc(supplementId).get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!['createdBy'] == FirebaseAuth.instance.currentUser?.uid) {
                                return Text(snapshot.data!['name']);
                              }
                              return const Text('');
                            },
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
