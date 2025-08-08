import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Map<String, Color> itemTypeColors = {
  'supplement': Colors.blue,
  'symptom': Colors.red,
  'medication': Colors.green,
  'food': Colors.orange,
};

extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}

Future<String> getItemName(String itemType, String? itemId) async {
  if (itemId == null || itemId.isEmpty) {
    return 'No Item';
  }
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection(itemType == 'supplement' ? 'supplements' : 'symptoms')
        .where('createdBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();

    for (var doc in querySnapshot.docs) {
      if (doc.id == itemId) {
        return (doc.data()?['name'] as String?) ?? 'Unknown';
      }
    }
    return 'Unknown';
  } catch (e) {
    return 'Unknown';
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('logEntries')
                .where('createdBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('date', isGreaterThanOrEqualTo: _selectedDay?.toUtc().startOfDay)
                .where('date', isLessThan: _selectedDay?.toUtc().endOfDay)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final events = <DateTime, List<String>>{};
                for (var doc in snapshot.data!.docs) {
                  final date = (doc['date'] as Timestamp).toDate();
                  final eventText = doc['notes'] as String;
                  final itemId = doc['itemId'] as String?;
                  final itemType = doc['type'] as String;

                  if (events[date] == null) {
                    events[date] = [
                      '$itemType:$itemId:$eventText'
                    ];
                  } else {
                    events[date]!.add('$itemType:$itemId:$eventText');
                  }
                }
                return Expanded(
                  child: ListView.builder(
                    itemCount: events.keys.length,
                    itemBuilder: (context, index) {
                      final date = events.keys.elementAt(index);
                      final eventList = events[date]!;
                      return Column(
                        children: eventList.map((event) {
                          final itemType = event.split(':')[0] ?? '';
                          final itemId = event.split(':')[1] ?? '';
                          final eventText = event.split(':')[2] ?? '';
                          if (itemId.isNotEmpty) {
                            return FutureBuilder<String>(
                              future: getItemName(itemType, itemId),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final itemName = snapshot.data!;
                                  return Container(
                                    color: itemTypeColors[itemType] ?? Colors.grey[200],
                                    child: ListTile(
                                      title: Text(date.toString()),
                                      subtitle: Text('$itemType: $itemName: $eventText'),
                                    ),
                                  );
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            );
                          } else {
                            return Container(
                              color: itemTypeColors[itemType] ?? Colors.grey[200],
                              child: ListTile(
                                title: Text(date.toString()),
                                subtitle: const Text('No Item'),
                              ),
                            );
                          }
                        }).toList(),
                      );
                    },
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Log Entry Screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
