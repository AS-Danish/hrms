// lib/models/TaskModel.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String taskTitle;
  final String taskDescription;
  final String assignedTo; // userId
  final String assignedToName;
  final String assignedToEmail;
  final String assignedBy; // HR userId
  final String assignedByName;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String status; // 'pending', 'in_progress', 'completed', 'not_completed'
  final DateTime assignedDate;
  final DateTime dueDate;
  final DateTime? completedDate;
  final String? completionNotes;
  final List<String> attachments; // URLs if any
  final Map<String, dynamic>? metadata; // Additional info

  TaskModel({
    required this.id,
    required this.taskTitle,
    required this.taskDescription,
    required this.assignedTo,
    required this.assignedToName,
    required this.assignedToEmail,
    required this.assignedBy,
    required this.assignedByName,
    required this.priority,
    required this.status,
    required this.assignedDate,
    required this.dueDate,
    this.completedDate,
    this.completionNotes,
    this.attachments = const [],
    this.metadata,
  });

  factory TaskModel.fromFirestore(Map<String, dynamic> data, String docId) {
    final assignedDateTimestamp = data['assignedDate'] as Timestamp?;
    final dueDateTimestamp = data['dueDate'] as Timestamp?;
    final completedDateTimestamp = data['completedDate'] as Timestamp?;

    return TaskModel(
      id: docId,
      taskTitle: data['taskTitle'] ?? 'Untitled Task',
      taskDescription: data['taskDescription'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      assignedToName: data['assignedToName'] ?? 'Unknown',
      assignedToEmail: data['assignedToEmail'] ?? '',
      assignedBy: data['assignedBy'] ?? '',
      assignedByName: data['assignedByName'] ?? 'Unknown',
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'pending',
      assignedDate: assignedDateTimestamp?.toDate() ?? DateTime.now(),
      dueDate: dueDateTimestamp?.toDate() ?? DateTime.now(),
      completedDate: completedDateTimestamp?.toDate(),
      completionNotes: data['completionNotes'],
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskTitle': taskTitle,
      'taskDescription': taskDescription,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedToEmail': assignedToEmail,
      'assignedBy': assignedBy,
      'assignedByName': assignedByName,
      'priority': priority,
      'status': status,
      'assignedDate': Timestamp.fromDate(assignedDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'completedDate': completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'completionNotes': completionNotes,
      'attachments': attachments,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != 'completed';

  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }
}