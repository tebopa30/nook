import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo.currentUser == null) {
      try {
        await authRepo.signInAnonymously();
      } catch (e) {
        debugPrint('Auth Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to react to changes if needed
    ref.watch(authStateProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/home_bg_v2.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black54,
              BlendMode.darken,
            ),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppTheme.accentGold),
                    onPressed: () => context.push('/settings'),
                  ),
                ),
              ),
              const Spacer(flex: 1),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nook',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                        letterSpacing: 12.0,
                        fontFamily: 'serif',
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 15, offset: const Offset(0, 4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '─ Elegance in Every Word ─',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 3.0,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4, offset: const Offset(0, 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // メインメニュー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildMenuButton(
                      context,
                      title: '想いを綴る',
                      subtitle: '大切な人へ、特別な一通を。',
                      icon: Icons.edit_note_rounded,
                      onTap: () => context.push('/create'),
                    ),
                    const SizedBox(height: 24),
                    _buildMenuButton(
                      context,
                      title: 'ポストを開く',
                      subtitle: '届いた言葉、綴った想いを辿る。',
                      icon: Icons.mark_as_unread_rounded,
                      onTap: () => context.push('/archive'),
                    ),
                    const SizedBox(height: 48),
                    _buildStoreButton(
                      context,
                      onTap: () => context.push('/store'),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Row(
            children: [
              Icon(icon, size: 36, color: AppTheme.accentGold),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.accentGold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreButton(BuildContext context, {required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
        side: BorderSide(color: AppTheme.accentGold.withOpacity(0.5), width: 1.5),
        backgroundColor: AppTheme.accentGold.withOpacity(0.05),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 24),
          SizedBox(width: 16),
          Text(
            'Nook store',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
