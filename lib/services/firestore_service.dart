import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service class handling all Firebase operations for report submission.
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image file to Firebase Storage and returns the download URL.
  static Future<String> uploadImage(
    File imageFile, {
    required String reportId,
  }) async {
    final ref = _storage.ref().child('reports/$reportId.jpg');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Saves report metadata to Firestore.
  static Future<DocumentReference> saveReport({
    required String reportId,
    required String category,
    required String description,
    required double severity,
    required double latitude,
    required double longitude,
    required String? imageUrl,
    required String streetName,
  }) async {
    return _firestore.collection('reports').doc(reportId).set({
      'category': category,
      'description': description,
      'severity': severity,
      'status': 'Pending',
      'location': GeoPoint(latitude, longitude),
      'streetName': streetName,
      'imageUrl': imageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).then((_) => _firestore.collection('reports').doc(reportId));
  }
}
