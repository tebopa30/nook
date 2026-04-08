import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../data/letter_repository.dart';
import '../domain/letter.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Letter> _sentLetters = [];
  List<Letter> _receivedLetters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLetters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLetters() async {
    final repo = ref.read(letterRepositoryProvider);
    final sent = await repo.getSentLetters();
    final received = await repo.getReceivedLetters();
    
    if (mounted) {
      setState(() {
        _sentLetters = sent;
        _receivedLetters = received;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文箱', style: TextStyle(fontFamily: 'serif', letterSpacing: 2)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentGold,
          unselectedLabelColor: Colors.white38,
          indicatorColor: AppTheme.accentGold,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: '届いた一通'),
            Tab(text: '綴った一通'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLetterList(_receivedLetters, isReceived: true),
                _buildLetterList(_sentLetters, isReceived: false),
              ],
            ),
    );
  }

  Widget _buildLetterList(List<Letter> letters, {required bool isReceived}) {
    if (letters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.accentGold.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(
              isReceived ? 'まだ手紙は届いていないようです' : 'まだ手紙を綴っていないようです',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final letter = letters[index];
        final name = isReceived ? '${letter.senderName} より' : '${letter.toName} へ';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          child: InkWell(
            onTap: () {
              if (letter.id != null) {
                context.push('/letter/${letter.id}');
              }
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: const Text('手紙を整理しますか？', style: TextStyle(color: AppTheme.accentGold, fontFamily: 'serif')),
                  content: const Text('この手紙を文箱から削除します。\n（この操作は元に戻せません）', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: const Text('残す', style: TextStyle(color: Colors.white38))
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (letter.id != null) {
                          await ref.read(letterRepositoryProvider).deleteLetter(letter.id!);
                          _loadLetters();
                        }
                      },
                      child: const Text('削除する', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                   _buildLetterIcon(isReceived, letter.isOpened),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'serif'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${letter.createdAt.year}/${letter.createdAt.month.toString().padLeft(2, '0')}/${letter.createdAt.day.toString().padLeft(2, '0')} 投函',
                          style: const TextStyle(fontSize: 12, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  if (!letter.isOpened && !isReceived)
                    const Icon(Icons.lock_clock_outlined, size: 20, color: Colors.white24)
                  else
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.accentGold),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLetterIcon(bool isReceived, bool isOpened) {
    if (isReceived) {
      if (!isOpened) {
        // 未開封：立体的な赤いシーリングワックスアイコン
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.shade900,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(2, 2))
            ],
            border: Border.all(color: Colors.white10, width: 0.5),
          ),
          child: const Center(
            child: Icon(Icons.bookmark_added, color: Colors.white, size: 24),
          ),
        );
      } else {
        // 開封済み：通常の封筒アイコン
        return const Icon(Icons.drafts_outlined, color: AppTheme.accentGold, size: 32);
      }
    } else {
      // 自分が送った手紙
      return const Icon(Icons.history_edu, color: AppTheme.accentGold, size: 32);
    }
  }
}
