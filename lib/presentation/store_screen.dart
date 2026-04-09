import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';
import '../data/payment_repository.dart';
import '../core/theme/app_theme.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  List<Package> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final paymentRepo = ref.read(paymentRepositoryProvider);
    final packages = await paymentRepo.getOfferings();
    if (mounted) {
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() => _isLoading = true);
    final paymentRepo = ref.read(paymentRepositoryProvider);
    final success = await paymentRepo.purchasePackage(package);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入が完了しました。ありがとうございます！')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入がキャンセルされたか、エラーが発生しました')),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    final paymentRepo = ref.read(paymentRepositoryProvider);
    final success = await paymentRepo.restorePurchases();
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '購入情報を復元しました' : '復元できる情報はありませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Nook Store', style: TextStyle(fontFamily: 'serif', letterSpacing: 2)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _restorePurchases,
            child: const Text('復元', style: TextStyle(color: AppTheme.accentGold)),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
          : _packages.isEmpty
              ? _buildMockUI()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
                  itemCount: _packages.length,
                  itemBuilder: (context, index) {
                    final package = _packages[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(package.storeProduct.title, style: const TextStyle(color: Colors.white, fontFamily: 'serif')),
                        subtitle: Text(package.storeProduct.description, style: const TextStyle(color: Colors.white70)),
                        trailing: OutlinedButton(
                          onPressed: () => _purchasePackage(package),
                          child: Text(package.storeProduct.priceString),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMockUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryDark, Colors.black],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
        children: [
          const Text(
            '─ Elegant Stationery ─',
            style: TextStyle(fontSize: 12, letterSpacing: 4, color: AppTheme.accentGold, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'プレミアムプラン',
            style: TextStyle(
              fontSize: 32, 
              fontWeight: FontWeight.bold, 
              fontFamily: 'serif', 
              color: Colors.white, 
              shadows: [Shadow(color: AppTheme.accentGold, blurRadius: 15)]
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            '想いを封印し、時を超えるための\n特別な道具たちがあなたを待っています。',
            style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.8),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          
          // Subscription Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: -5,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                   Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.star_rounded, size: 100, color: AppTheme.accentGold.withOpacity(0.1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nook Premium',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'serif', color: AppTheme.accentGold),
                            ),
                            Icon(Icons.stars_rounded, color: AppTheme.accentGold, size: 28),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '制限を解放し、\n一通の手紙にさらなる慈しみを。',
                          style: TextStyle(height: 1.6, color: Colors.white70),
                        ),
                        const SizedBox(height: 28),
                        _buildFeatureRow(Icons.photo_library_outlined, '写真添付の制限解除（最大3枚まで）'),
                        _buildFeatureRow(Icons.edit_calendar_rounded, '10年先までの配達指定が可能'),
                        _buildFeatureRow(Icons.palette_outlined, '限定カラーのワックスと全デザイン解放'),
                        const SizedBox(height: 36),
                        
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                            ),
                            child: const Text('【 初月無料 】体験期間中', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {},
                            child: const Text('プレミアムプランに加入', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text('プラン継続時は月額 300円', style: TextStyle(fontSize: 12, color: Colors.white38)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 60),
          _buildStationeryGallery(),
          const SizedBox(height: 60),
          _buildBenefitsSection(),
          const SizedBox(height: 60),
          
          // Consumable Section
          const Center(
            child: Text(
              '─ 切手 ─',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'serif', color: AppTheme.accentGold),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 180,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGold.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: -10,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/time_capsule_stamp.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'タイムカプセル切手',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'serif'),
                  ),
                  const SizedBox(height: 8),
                  const Text('1枚 / 100円', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.accentGold)),
                  const SizedBox(height: 20),
                  const Text(
                    '1ヶ月から10年の時を刻み、未来へ想いを届けるための特別な切手。\n一通につき、すべての封筒・便箋デザインが解放されます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.7, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () {},
                      label: const Text('切手を購入する', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),
          _buildLegalFooter(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLegalFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.push('/terms'),
              child: const Text('利用規約', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
            const Text(' | ', style: TextStyle(color: Colors.white10, fontSize: 11)),
            TextButton(
              onPressed: () => context.push('/privacy'),
              child: const Text('プライバシーポリシー', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '© 2026 Nook Team',
          style: TextStyle(color: Colors.white10, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppTheme.accentGold),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            '─ 特別な一通のために ─',
            style: TextStyle(color: AppTheme.accentGold, fontSize: 14, fontFamily: 'serif', fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildBenefitItem(Icons.color_lens_outlined, '多彩なデザイン', '切手またはプレミアムで、すべての封筒・便箋が選択可能になります。'),
          const SizedBox(height: 16),
          _buildBenefitItem(Icons.history_edu, '時を超える手紙', '1週間以上先の指定（タイムカプセル）が可能になります。'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String desc) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentGold, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStationeryGallery() {
    final designs = [
      {'name': 'ノーマル', 'icon': Icons.mail, 'color': Colors.grey, 'asset': 'assets/images/human_paper_texture.png'},
      {'name': '和風', 'icon': Icons.filter_vintage, 'color': const Color(0xFFC5E1A5), 'asset': 'assets/images/japanese_paper.png'},
      {'name': '西洋風', 'icon': Icons.history_edu, 'color': const Color(0xFFD7CCC8), 'asset': 'assets/images/western_paper.png'},
      {'name': '記念日', 'icon': Icons.auto_awesome, 'color': const Color(0xFFFFD700), 'asset': 'assets/images/anniversary_paper.png'},
      {'name': '誕生日', 'icon': Icons.cake, 'color': const Color(0xFFFFAB91), 'asset': 'assets/images/birthday_paper.png'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '─ Stationery Gallery ─',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif', color: AppTheme.accentGold),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: designs.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final d = designs[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (d['color'] as Color).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: (d['color'] as Color).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: Image.asset(
                          d['asset'] as String,
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(0.8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(d['icon'] as IconData, size: 16, color: d['color'] as Color),
                            const SizedBox(height: 4),
                            Text(
                              d['name'] as String,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
