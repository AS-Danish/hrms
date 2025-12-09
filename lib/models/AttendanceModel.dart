// lib/models/AttendanceModel.dart

// 1. ADD THIS IMPORT
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String email;
  final String date; // 'yyyy-MM-dd'
  final String loginTime; // 'HH:mm:ss'
  final String status; // 'present', 'absent', 'on_leave' (assuming HR can edit)
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime markedAt; // Use DateTime for easier sorting/filtering

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.email,
    required this.date,
    required this.loginTime,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.markedAt,
  });

  factory AttendanceModel.fromFirestore(Map<String, dynamic> data, String docId) {
    final location = data['location'] as Map<String, dynamic>? ?? {};

    // The Timestamp type is now correctly recognized
    final markedAtTimestamp = data['markedAt'] as Timestamp?;

    return AttendanceModel(
      id: docId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'N/A',
      userRole: data['userRole'] ?? 'N/A',
      email: data['email'] ?? 'N/A',
      date: data['date'] ?? 'N/A',
      loginTime: data['loginTime'] ?? 'N/A',
      status: data['status'] ?? 'N/A',
      latitude: (location['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (location['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (location['accuracy'] as num?)?.toDouble() ?? 0.0,
      markedAt: markedAtTimestamp?.toDate() ?? DateTime(0),
    );
  }
}