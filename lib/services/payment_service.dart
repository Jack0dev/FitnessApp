import 'dart:convert';
import '../models/enrollment_model.dart';
import 'course_service.dart';
import 'sql_database_service.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling payment processing
/// Currently supports QR code payment simulation
class PaymentService {
  SqlDatabaseService? _sqlService;
  final CourseService _courseService;

  PaymentService() : _courseService = CourseService() {
    _sqlService = SqlDatabaseService();
  }

  /// Parse QR code data from scanned QR code
  /// Returns payment information if valid
  Map<String, dynamic>? parseQRCodeData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      
      // Validate QR code format
      if (data['type'] == 'course_enrollment_payment' &&
          data['enrollment_id'] != null &&
          data['course_id'] != null &&
          data['amount'] != null) {
        return data;
      }
      
      return null;
    } catch (e) {
      print('Error parsing QR code data: $e');
      return null;
    }
  }

  /// Confirm payment after QR code is scanned and payment is successful
  /// This will update payment_status to 'paid' which triggers database trigger
  Future<bool> confirmPaymentFromQR({
    required String enrollmentId,
    required String transactionId,
    required double amount,
  }) async {
    if (_sqlService == null) {
      throw Exception('Supabase not initialized');
    }

    try {
      // Get current enrollment to verify
      final response = await _sqlService!.client
          .from('enrollments')
          .select()
          .eq('id', enrollmentId)
          .single();

      if (response == null) {
        throw Exception('Enrollment not found');
      }

      final enrollment = EnrollmentModel.fromSupabase(response);

      // Verify amount matches
      if ((enrollment.amountPaid ?? 0) != amount) {
        throw Exception('Payment amount mismatch');
      }

      // Verify payment status is still pending
      if (enrollment.paymentStatus != PaymentStatus.pending) {
        throw Exception('Enrollment payment status is not pending');
      }

      // Update payment status to paid
      // This will trigger the database trigger to:
      // 1. Update enrollment payment_status = 'paid'
      // 2. Increment course current_students
      // 3. Update user enrollment information
      final updateResponse = await _courseService.confirmPayment(
        enrollmentId: enrollmentId,
        transactionId: transactionId,
      );

      if (updateResponse) {
        print('✅ [PaymentService] Payment confirmed successfully');
        
        // Verify trigger executed by checking updated enrollment
        final updatedEnrollment = await _sqlService!.client
            .from('enrollments')
            .select()
            .eq('id', enrollmentId)
            .single();

        final updated = EnrollmentModel.fromSupabase(updatedEnrollment);
        if (updated.paymentStatus == PaymentStatus.paid) {
          print('✅ [PaymentService] Payment status updated to paid');
          print('✅ [PaymentService] Database trigger should have updated course and user data');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ [PaymentService] Error confirming payment: $e');
      return false;
    }
  }

  /// Simulate payment confirmation (for testing)
  /// In production, this would be called by payment gateway webhook
  Future<bool> simulatePaymentConfirmation({
    required String enrollmentId,
    required String transactionId,
  }) async {
    try {
      // Get enrollment amount
      final response = await _sqlService!.client
          .from('enrollments')
          .select()
          .eq('id', enrollmentId)
          .single();

      if (response == null) {
        return false;
      }

      final enrollment = EnrollmentModel.fromSupabase(response);
      final amount = enrollment.amountPaid ?? 0;

      // Confirm payment
      return await confirmPaymentFromQR(
        enrollmentId: enrollmentId,
        transactionId: transactionId,
        amount: amount,
      );
    } catch (e) {
      print('❌ [PaymentService] Error simulating payment: $e');
      return false;
    }
  }
}

