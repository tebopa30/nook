import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// 画像を圧縮してFirebase Storageにアップロードし、ダウンロードURLを返す
  Future<String> uploadCompressedImage(String localPath) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      throw Exception('File does not exist at $localPath');
    }

    // 1. 圧縮処理
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, '${_uuid.v4()}.webp');
    
    final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
      localPath,
      targetPath,
      quality: 80, // 画質と容量のバランスが良い設定
      format: CompressFormat.webp, // WebPは高圧縮かつ高画質
    );

    if (compressedFile == null) {
      throw Exception('Compression failed');
    }

    // 2. アップロード処理
    final storagePath = 'letters/photos/${_uuid.v4()}.webp';
    final ref = _storage.ref().child(storagePath);
    
    final uploadTask = ref.putFile(File(compressedFile.path));
    final snapshot = await uploadTask;
    
    // 3. URLの取得
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    // 4. 一時ファイルの削除
    try {
      await File(compressedFile.path).delete();
    } catch (_) {
      // 失敗してもクリティカルではない
    }

    return downloadUrl;
  }
}
