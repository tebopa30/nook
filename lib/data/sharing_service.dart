import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

final sharingServiceProvider = Provider<SharingService>((ref) {
  return SharingService();
});

class SharingService {
  /// 手紙閲覧用のURLを生成・共有する
  /// LINE連携を意図した汎用的な共有ダイアログを呼び出します
  Future<void> shareLetterUrl(String letterId) async {
    // Web閲覧用のURL（本番環境ではFirebase Hosting等のドメインになります）
    final url = 'https://nook-app.web.app/letters/$letterId';
    
    final shareText = '💌 大切な手紙が届いています。\n\n以下のリンクから、封を開いて読み進めてください。\n\n$url\n\n#Nook #デジタルレター';
    
    // subject はメール等で使用されます
    await Share.share(shareText, subject: 'Nookからの手紙');
  }
}
