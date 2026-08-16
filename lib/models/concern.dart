import 'package:cloud_firestore/cloud_firestore.dart';

class ConcernComment {
  final String author;
  final String comment;
  final DateTime timestamp;
  final bool isAdminReply;

  ConcernComment({
    required this.author,
    required this.comment,
    required this.timestamp,
    this.isAdminReply = true,
  });

  factory ConcernComment.fromMap(Map<String, dynamic> map) {
    return ConcernComment(
      author: map['author'] ?? 'Admin',
      comment: map['comment'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAdminReply: map['isAdminReply'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'author': author,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAdminReply': isAdminReply,
    };
  }
}

class Concern {
  final String id;
  final String title;
  final String description;
  final String category;
  final String raisedBy;
  final String flatNumber;
  final DateTime dateRaised;
  final String status; // 'Open', 'In Progress', 'Resolved'
  final List<ConcernComment> comments;

  Concern({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.raisedBy,
    required this.flatNumber,
    required this.dateRaised,
    this.status = 'Open',
    this.comments = const [],
  });

  factory Concern.fromMap(Map<String, dynamic> map, String id) {
    var rawComments = map['comments'] as List<dynamic>? ?? [];
    List<ConcernComment> commentsList = rawComments.map((c) => ConcernComment.fromMap(Map<String, dynamic>.from(c))).toList();

    return Concern(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      raisedBy: map['raisedBy'] ?? 'Resident',
      flatNumber: map['flatNumber'] ?? '',
      dateRaised: (map['dateRaised'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'Open',
      comments: commentsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'raisedBy': raisedBy,
      'flatNumber': flatNumber,
      'dateRaised': Timestamp.fromDate(dateRaised),
      'status': status,
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }
}
