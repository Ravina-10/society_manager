import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String content;
  final String category;
  final String priority;
  final String postedBy;
  final DateTime datePosted;
  final bool isActive;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'General',
    this.priority = 'Normal',
    this.postedBy = 'Martand Niwas Management',
    required this.datePosted,
    this.isActive = true,
  });

  factory Notice.fromMap(Map<String, dynamic> map, String id) {
    return Notice(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'General',
      priority: map['priority'] ?? 'Normal',
      postedBy: map['postedBy'] ?? 'Martand Niwas Management',
      datePosted: (map['datePosted'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'priority': priority,
      'postedBy': postedBy,
      'datePosted': Timestamp.fromDate(datePosted),
      'isActive': isActive,
    };
  }
}
