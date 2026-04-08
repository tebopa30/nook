import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final isInitialized = ref.watch(firebaseInitializedProvider);
  if (isInitialized) {
    return FirebaseStorageRepository(FirebaseStorage.instance);
  } else {
    return MockStorageRepository();
  }
});

abstract class StorageRepository {
  Future<String> uploadPhoto(File file, String userId);
}

class FirebaseStorageRepository implements StorageRepository {
  final FirebaseStorage _storage;

  FirebaseStorageRepository(this._storage);

  @override
  Future<String> uploadPhoto(File file, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = _storage.ref().child('users/$userId/photos/$fileName');
    
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}

class MockStorageRepository implements StorageRepository {
  @override
  Future<String> uploadPhoto(File file, String userId) async {
    // Return a dummy URL for local testing
    return 'https://example.com/mock_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}
