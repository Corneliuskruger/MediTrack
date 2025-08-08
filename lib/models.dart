import 'package:cloud_firestore/cloud_firestore.dart';

class Supplement {
  final String id;
  final String name;
  final String? dosage;
  final String? note;
  final String createdBy;
  final Timestamp createdAt;

  Supplement({
    required this.id,
    required this.name,
    this.dosage,
    this.note,
    required this.createdBy,
    required this.createdAt,
  });
}

class Symptom {
  final String id;
  final String name;
  final int? severityScale;
  final String createdBy;
  final Timestamp createdAt;

  Symptom({
    required this.id,
    required this.name,
    this.severityScale,
    required this.createdBy,
    required this.createdAt,
  });
}

class FavoriteGroup {
  final String id;
  final String type;
  final String name;
  final String colorHex;
  final List<String> items;
  final String createdBy;
  final Timestamp createdAt;

  FavoriteGroup({
    required this.id,
    required this.type,
    required this.name,
    required this.colorHex,
    required this.items,
    required this.createdBy,
    required this.createdAt,
  });
}

class LogEntry {
  final String id;
  final String type;
  final String userId;
  final String itemId;
  final String? favoriteGroupId;
  final Timestamp date;
  final String? notes;
  final int? severity;
  final Timestamp createdAt;

  LogEntry({
    required this.id,
    required this.type,
    required this.userId,
    required this.itemId,
    this.favoriteGroupId,
    required this.date,
    this.notes,
    this.severity,
    required this.createdAt,
  });
}
