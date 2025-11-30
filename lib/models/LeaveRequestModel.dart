import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequestModel {
  final String id;
  final String userId;
  final String employeeId;
  final String employeeEmail;
  final String? employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfDays;
  final String note;
  final String? documentUrl;
  final String? documentName;
  final String status;
  final DateTime createdAt;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.employeeId,
    required this.employeeEmail,
    this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    required this.note,
    this.documentUrl,
    this.documentName,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory LeaveRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaveRequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      employeeId: data['employeeId'] ?? '',
      employeeEmail: data['employeeEmail'] ?? '',
      employeeName: data['employeeName'],
      leaveType: data['leaveType'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      numberOfDays: data['numberOfDays'] ?? 0,
      note: data['note'] ?? '',
      documentUrl: data['documentUrl'],
      documentName: data['documentName'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      rejectionReason: data['rejectionReason'],
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'employeeId': employeeId,
      'employeeEmail': employeeEmail,
      'employeeName': employeeName,
      'leaveType': leaveType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'numberOfDays': numberOfDays,
      'note': note,
      'documentUrl': documentUrl,
      'documentName': documentName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'rejectionReason': rejectionReason,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }
}