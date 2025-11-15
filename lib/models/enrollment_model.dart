/// Enrollment model - User enrollment in a course
class EnrollmentModel {
  final String id;
  final String userId;
  final String courseId;
  final String? courseTitle;
  final PaymentStatus paymentStatus;
  final DateTime enrolledAt;
  final DateTime? paymentAt;
  final double? amountPaid;
  final String? transactionId;

  EnrollmentModel({
    required this.id,
    required this.userId,
    required this.courseId,
    this.courseTitle,
    this.paymentStatus = PaymentStatus.pending,
    required this.enrolledAt,
    this.paymentAt,
    this.amountPaid,
    this.transactionId,
  });

  /// Create from Firestore
  factory EnrollmentModel.fromFirestore(Map<String, dynamic> doc, String id) {
    return EnrollmentModel(
      id: id,
      userId: doc['userId'] as String,
      courseId: doc['courseId'] as String,
      courseTitle: doc['courseTitle'] as String?,
      paymentStatus: PaymentStatus.fromString(doc['paymentStatus'] as String?),
      enrolledAt: _parseTimestamp(doc['enrolledAt']),
      paymentAt: _parseTimestamp(doc['paymentAt']),
      amountPaid: (doc['amountPaid'] as num?)?.toDouble(),
      transactionId: doc['transactionId'] as String?,
    );
  }

  /// Create from Supabase
  factory EnrollmentModel.fromSupabase(Map<String, dynamic> doc) {
    return EnrollmentModel(
      id: doc['id'] as String,
      userId: doc['user_id'] as String,
      courseId: doc['course_id'] as String,
      courseTitle: doc['course_title'] as String?,
      paymentStatus: PaymentStatus.fromString(doc['payment_status'] as String?),
      enrolledAt: doc['enrolled_at'] != null
          ? DateTime.parse(doc['enrolled_at'] as String)
          : DateTime.now(),
      paymentAt: doc['payment_at'] != null
          ? DateTime.parse(doc['payment_at'] as String)
          : null,
      amountPaid: (doc['amount_paid'] as num?)?.toDouble(),
      transactionId: doc['transaction_id'] as String?,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    try {
      return timestamp.toDate() as DateTime;
    } catch (e) {
      if (timestamp is Map) {
        final seconds = timestamp['_seconds'] as int?;
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }
      return DateTime.now();
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'courseId': courseId,
      if (courseTitle != null) 'courseTitle': courseTitle,
      'paymentStatus': paymentStatus.value,
      'enrolledAt': enrolledAt,
      if (paymentAt != null) 'paymentAt': paymentAt,
      if (amountPaid != null) 'amountPaid': amountPaid,
      if (transactionId != null) 'transactionId': transactionId,
    };
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'course_id': courseId,
      if (courseTitle != null) 'course_title': courseTitle,
      'payment_status': paymentStatus.value,
      'enrolled_at': enrolledAt.toIso8601String(),
      if (paymentAt != null) 'payment_at': paymentAt!.toIso8601String(),
      if (amountPaid != null) 'amount_paid': amountPaid,
      if (transactionId != null) 'transaction_id': transactionId,
    };
  }
}

/// Payment status enum
enum PaymentStatus {
  pending('pending', 'Pending'),
  paid('paid', 'Paid'),
  failed('failed', 'Failed'),
  refunded('refunded', 'Refunded');

  final String value;
  final String displayName;

  const PaymentStatus(this.value, this.displayName);

  static PaymentStatus fromString(String? value) {
    if (value == null) return PaymentStatus.pending;
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );
  }
}


