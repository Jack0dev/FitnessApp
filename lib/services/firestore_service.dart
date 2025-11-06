import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get Firestore instance
  FirebaseFirestore get instance => _firestore;

  /// Check if Firestore error is permission denied
  bool _isPermissionDenied(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied' ||
          error.message?.contains('PERMISSION_DENIED') == true ||
          error.message?.contains('API has not been used') == true ||
          error.message?.contains('disabled') == true;
    }
    return error.toString().contains('PERMISSION_DENIED') ||
        error.toString().contains('API has not been used') ||
        error.toString().contains('disabled');
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (_isPermissionDenied(error)) {
      return 'Firestore API is not enabled. Please enable it in Firebase Console.';
    }
    return 'Failed to add document: ${error.toString()}';
  }

  /// Add document to collection
  Future<void> addDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? docId,
  }) async {
    try {
      if (docId != null) {
        await _firestore.collection(collection).doc(docId).set(data);
      } else {
        await _firestore.collection(collection).add(data);
      }
    } catch (e) {
      throw _getErrorMessage(e);
    }
  }

  /// Update document (creates if not exists)
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Use set with merge: true to create if not exists, or update if exists
      await _firestore.collection(collection).doc(docId).set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      if (_isPermissionDenied(e)) {
        throw _getErrorMessage(e);
      }
      throw 'Failed to update document: ${e.toString()}';
    }
  }

  /// Delete document
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      if (_isPermissionDenied(e)) {
        throw _getErrorMessage(e);
      }
      throw 'Failed to delete document: ${e.toString()}';
    }
  }

  /// Get document
  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      if (_isPermissionDenied(e)) {
        throw _getErrorMessage(e);
      }
      throw 'Failed to get document: ${e.toString()}';
    }
  }

  /// Get documents stream
  Stream<QuerySnapshot> getDocumentsStream({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }

  /// Get user document
  Future<DocumentSnapshot?> getUserDocument(String userId) async {
    try {
      return await getDocument(
        collection: AppConstants.usersCollection,
        docId: userId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create or update user document
  /// Returns true if successful, false if Firestore is not available
  Future<bool> saveUserData({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set(userData, SetOptions(merge: true));
      return true;
    } catch (e) {
      // If Firestore is not enabled, return false but don't throw
      // This allows the app to continue working without Firestore
      if (_isPermissionDenied(e)) {
        return false;
      }
      throw _getErrorMessage(e);
    }
  }
}

