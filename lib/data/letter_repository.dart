import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/letter.dart';
import '../main.dart';
import 'auth_repository.dart';

final letterRepositoryProvider = Provider<LetterRepository>((ref) {
  final isInitialized = ref.watch(firebaseInitializedProvider);
  if (isInitialized) {
    final authRepo = ref.read(authRepositoryProvider);
    return FirebaseLetterRepository(FirebaseFirestore.instance, authRepo);
  } else {
    return MockLetterRepository();
  }
});

abstract class LetterRepository {
  Future<String> createLetter(Letter letter);
  Future<Letter?> getLetter(String id);
  Future<void> markAsOpened(String id);
  Future<List<Letter>> getSentLetters();
  Future<List<Letter>> getReceivedLetters();
  Future<void> saveReceivedLetterId(String id);
  Future<void> deleteLetter(String id);
}

class FirebaseLetterRepository implements LetterRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepo;

  FirebaseLetterRepository(this._firestore, this._authRepo);

  CollectionReference<Map<String, dynamic>> get _lettersRef =>
      _firestore.collection('letters');

  @override
  Future<String> createLetter(Letter letter) async {
    final uid = _authRepo.currentUser?.uid;
    final finalLetter = letter.senderUid == null ? letter.copyWith(senderUid: uid) : letter;
    
    if (finalLetter.id != null && finalLetter.id!.isNotEmpty) {
      await _lettersRef.doc(finalLetter.id).set(finalLetter.toJson());
      return finalLetter.id!;
    } else {
      final docRef = await _lettersRef.add(finalLetter.toJson());
      return docRef.id;
    }
  }

  @override
  Future<Letter?> getLetter(String id) async {
    final doc = await _lettersRef.doc(id).get();
    if (!doc.exists) return null;
    return Letter.fromJson(doc.data()!, id: doc.id);
  }

  @override
  Future<void> markAsOpened(String id) async {
    await _lettersRef.doc(id).update({'isOpened': true});
  }

  @override
  Future<List<Letter>> getSentLetters() async {
    final uid = _authRepo.currentUser?.uid;
    if (uid == null) return [];
    
    final query = await _lettersRef
        .where('senderUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) => Letter.fromJson(doc.data(), id: doc.id)).toList();
  }

  @override
  Future<List<Letter>> getReceivedLetters() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('received_letter_ids') ?? [];
    
    if (ids.isEmpty) return [];

    final List<Letter> letters = [];
    for (final id in ids) {
      final letter = await getLetter(id);
      if (letter != null) {
        letters.add(letter);
      }
    }
    
    // CreateAtで降順ソート
    letters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return letters;
  }

  @override
  Future<void> saveReceivedLetterId(String id) async {
    if (id.contains('dummy')) return;
    
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('received_letter_ids') ?? [];
    
    if (!ids.contains(id)) {
      ids.add(id);
      await prefs.setStringList('received_letter_ids', ids);
    }
  }

  @override
  Future<void> deleteLetter(String id) async {
    await _lettersRef.doc(id).delete();
  }
}

class MockLetterRepository implements LetterRepository {
  final Map<String, Letter> _letters = {};

  @override
  Future<String> createLetter(Letter letter) async {
    final id = letter.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _letters[id] = letter.copyWith(id: id);
    return id;
  }

  @override
  Future<Letter?> getLetter(String id) async {
    return _letters[id];
  }

  @override
  Future<void> markAsOpened(String id) async {
    if (_letters.containsKey(id)) {
      _letters[id] = _letters[id]!.copyWith(isOpened: true);
    }
  }

  @override
  Future<List<Letter>> getSentLetters() async {
    final list = _letters.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<Letter>> getReceivedLetters() async {
    // モックとしては開封済みのものを届いた手紙として扱う等のダミー実装
    final list = _letters.values.where((l) => l.isOpened).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // ダミーの受信手紙を追加して見せる
    if (list.isEmpty) {
      list.add(
        Letter(
          id: 'dummy_received',
          toName: 'あなた',
          senderName: 'Nook',
          content: 'Nookへようこそ。最初のダミーレターです。',
          themeId: 'default',
          unlockTime: DateTime.now().subtract(const Duration(days: 1)),
          isOpened: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
    }
    return list;
  }

  @override
  Future<void> saveReceivedLetterId(String id) async {
    // モック実装
  }

  @override
  Future<void> deleteLetter(String id) async {
    _letters.remove(id);
  }
}
