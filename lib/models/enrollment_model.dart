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

  /// Create from Supabase row
  factory EnrollmentModel.fromSupabase(Map<String, dynamic> doc) {
    DateTime _parseDate(dynamic value, {required DateTime fallback}) {
      if (value == null) return fallback;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return fallback;
        }
      }
      return fallback;
    }

    return EnrollmentModel(
      id: doc['id'] as String,
      userId: doc['user_id'] as String,
      courseId: doc['course_id'] as String,
      courseTitle: doc['course_title'] as String?,
      paymentStatus: PaymentStatus.fromString(doc['payment_status'] as String?),
      enrolledAt: _parseDate(doc['enrolled_at'], fallback: DateTime.now()),
      paymentAt: doc['payment_at'] != null
          ? _parseDate(doc['payment_at'], fallback: DateTime.now())
          : null,
      amountPaid: (doc['amount_paid'] as num?)?.toDouble(),
      transactionId: doc['transaction_id'] as String?,
    );
  }

  /// Convert to Supabase insert/update payload
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
