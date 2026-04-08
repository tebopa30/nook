import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_repository.dart';
import '../data/auth_repository.dart';
import '../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isPremiumSimulated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final status = await ref.read(paymentRepositoryProvider).isPremium;
    if (mounted) {
      setState(() => _isPremiumSimulated = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('アカウント'),
          _buildAccountStatus(),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Nook Store (課金)'),
            onTap: () => context.push('/store'),
          ),
          const Divider(),
          _buildSectionHeader('サポート・規約'),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('利用規約'),
            onTap: () => context.push('/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('プライバシーポリシー'),
            onTap: () => context.push('/privacy'),
          ),
          const Divider(),
          const ListTile(
            title: Text('バージョン'),
            trailing: Text('1.0.0'),
          ),
          if (kDebugMode) ...[
            const Divider(),
            _buildSectionHeader('デバッグ設定'),
            SwitchListTile(
              secondary: const Icon(Icons.bug_report_outlined, color: Colors.orange),
              title: const Text('プレミアムプラン擬似有効化'),
              subtitle: const Text('開発用のトグルスイッチです'),
              value: _isPremiumSimulated,
              onChanged: (value) {
                ref.read(paymentRepositoryProvider).togglePremiumSimulation(value);
                setState(() => _isPremiumSimulated = value);
              },
            ),
          ],
          const SizedBox(height: 40),
          Center(
            child: Text(
              '© 2026 Nook Team',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStatus() {
    final user = ref.watch(authStateProvider).value;
    final isAnonymous = user?.isAnonymous ?? true;

    return ListTile(
      leading: const Icon(Icons.account_circle_outlined),
      title: Text(isAnonymous ? 'ゲストユーザー' : (user?.email ?? 'ログイン済み')),
      subtitle: Text(isAnonymous ? 'データを保護するためにアカウント連携をお勧めします' : 'アカウントは保護されています'),
      trailing: isAnonymous 
          ? TextButton(
              onPressed: () {
                // Future: Implement Social Login Linking
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('アカウント連携機能は準備中です')),
                );
              }, 
              child: const Text('連携する')
            )
          : TextButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('ログアウト', style: TextStyle(color: Colors.red)),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
      ),
    );
  }
}
