import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

// Firebaseが正常に初期化されたかどうかを管理するプロバイダー
final firebaseInitializedProvider = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  
  // NOTE: Firebaseの実際のキーを設定するまでは、エラーをキャッチして無視するようにしています。
  bool isInitialized = false;
  try {
    await Firebase.initializeApp();
    isInitialized = true;
  } catch (e) {
    debugPrint('Firebase初期化失敗（キーが未設定のため）: $e');
  }

  // 初期化状態をプロバイダーに反映
  container.read(firebaseInitializedProvider.notifier).state = isInitialized;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NookApp(),
    ),
  );
}

class NookApp extends StatelessWidget {
  const NookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nook',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
