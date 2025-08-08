import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<User?> _user = ValueNotifier(FirebaseAuth.instance.currentUser);
  String _type = 'supplement';
  String? _selectedItem;
  String? _selectedFavoriteGroup;
  TimeOfDay _time = TimeOfDay.now();
  final _notesController = TextEditingController();
  double _severity = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ToggleButtons(
                isSelected: [_type == 'supplement', _type == 'symptom'],
                onPressed: (index) {
                  setState(() {
                    _type = index == 0 ? 'supplement' : 'symptom';
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Supplement'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Symptom'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (FirebaseAuth.instance.currentUser != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(_type == 'supplement' ? 'supplements' : 'symptoms')
                      .where('createdBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No items found.'));
                    }
                    final items = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _selectedItem,
                      hint: Text('Select a ${_type}'),
                      onChanged: (value) {
                        setState(() {
                          _selectedItem = value;
                        });
                      },
                      items: items.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item['name']),
                        );
                      }).toList(),
                    );
                  },
                ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseAuth.instance.currentUser != null ? FirebaseFirestore.instance.collection('favoriteGroups').where('type', isEqualTo: _type).where('createdBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid).snapshots() : null,
                builder: (context, snapshot) {
                  if (snapshot == null) {
                    return const Center(child: Text('Please log in to view favorite groups.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final items = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedFavoriteGroup,
                    hint: const Text('Select a Favorite Group (optional)'),
                    onChanged: (value) {
                      setState(() {
                        _selectedFavoriteGroup = value;
                      });
                    },
                    items: items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item['name']),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Time: ${_time.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: _pickTime,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              if (_type == 'symptom')
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Text('Severity: ${_severity.toInt()}'),
                    Slider(
                      value: _severity,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _severity.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _severity = value;
                        });
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (time != null) {
      setState(() {
        _time = time;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final itemId = _selectedItem;
          if (itemId != null) {
            final itemDoc = FirebaseFirestore.instance.collection(_type == 'supplement' ? 'supplements' : 'symptoms').doc(itemId);
            await itemDoc.update({'createdBy': user.uid});
          }
          FirebaseFirestore.instance.collection('logEntries').add({
            'type': _type,
            'createdBy': user.uid,
            'itemId': _selectedItem,
            'favoriteGroupId': _selectedFavoriteGroup,
            'date': Timestamp.now(),
            'notes': _notesController.text,
            'userId': user.uid,
            'severity': _type == 'symptom' ? _severity.toInt() : null,
            'createdAt': Timestamp.now(),
          });
          setState(() {
          _selectedItem = null;
          _selectedFavoriteGroup = null;
          _time = TimeOfDay.now();
          _notesController.clear();
          _severity = 5;
        });
        } catch (e) {
          print(e);
        }
      }
    }
  }
}
