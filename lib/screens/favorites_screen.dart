import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddFavoriteGroupDialog();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favoriteGroups')
            .where('createdBy', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No favorite groups found.'));
          }
          final groups = snapshot.data!.docs;
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(int.parse(group['colorHex'], radix: 16)),
                ),
                title: Text(group['name']),
                subtitle: Text(group['type']),
                onTap: () {
                  // TODO: Implement edit/delete functionality
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddFavoriteGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddFavoriteGroupForm();
      },
    );
  }
}

class AddFavoriteGroupForm extends StatefulWidget {
  const AddFavoriteGroupForm({super.key});

  @override
  State<AddFavoriteGroupForm> createState() => _AddFavoriteGroupFormState();
}

class _AddFavoriteGroupFormState extends State<AddFavoriteGroupForm> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'supplement';
  final _nameController = TextEditingController();
  final String _colorHex = 'FF4CAF50';
  List<String> _selectedItems = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Favorite Group'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToggleButtons(
                isSelected: [_type == 'supplement', _type == 'symptom'],
                onPressed: (index) {
                  setState(() {
                    _type = index == 0 ? 'supplement' : 'symptom';
                    _selectedItems = [];
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // TODO: Add color picker
              Text('Color: #$_colorHex'),
              const SizedBox(height: 16),
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
                  return Wrap(
                    spacing: 8.0,
                    children: items.map((item) {
                      return FilterChip(
                        label: Text(item['name']),
                        selected: _selectedItems.contains(item.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedItems.add(item.id);
                            } else {
                              _selectedItems.remove(item.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    print('Submit button pressed');
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('favoriteGroups').add({
          'type': _type,
          'name': _nameController.text,
          'colorHex': _colorHex,
          'items': _selectedItems,
          'createdBy': user.uid,
          'createdAt': Timestamp.now(),
        });
        Navigator.of(context).pop();
      }
    }
  }
}
