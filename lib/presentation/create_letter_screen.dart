import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../data/payment_repository.dart';
import '../data/letter_repository.dart';
import '../data/sharing_service.dart';
import '../data/advertisement_service.dart';
import '../domain/letter.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';

class CreateLetterScreen extends ConsumerStatefulWidget {
  const CreateLetterScreen({super.key});

  @override
  ConsumerState<CreateLetterScreen> createState() => _CreateLetterScreenState();
}

class _CreateLetterScreenState extends ConsumerState<CreateLetterScreen> {
  final _toController = TextEditingController();
  final _senderController = TextEditingController();
  final _contentController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final List<String> _attachedPhotos = [];
  final Map<String, String> _photoCaptions = {};
  bool _isLoading = false;
  int _currentTabIndex = 0; // 0: 本文, 1: オプション

  // Design states
  String _selectedEnvelope = 'ノーマル';
  String _selectedPaper = 'ノーマル';
  final List<String> _designOptions = ['ノーマル', 'ポップ', 'ラブレター風', '家族向け', '西洋風', '和風', '記念日', '誕生日'];

  // Font states
  final List<String> _fontOptions = [
    'Shippori Mincho',
    'Sawarabi Mincho',
    'Crimson Text',
    'Inter',
    'Roboto',
  ];
  String _selectedFont = 'Shippori Mincho';
  double _selectedSize = 18.0;
  bool _isBold = false;
  bool _showFormattingToolbar = true;

  // Security & Expiration states
  bool _passcodeEnabled = false;
  String _passcode = '';
  String _selectedExpiration = '無制限'; // 無制限, 24時間, 7日間, 30日間

  @override
  void dispose() {
    _toController.dispose();
    _senderController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  TextStyle _getContentStyle() {
    TextStyle style;
    try {
      style = GoogleFonts.getFont(
        _selectedFont,
        fontSize: _selectedSize,
        fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
        height: 2.2,
        letterSpacing: 1.5,
        color: const Color(0xFF3E2723),
      );
    } catch (_) {
      style = TextStyle(
        fontFamily: 'serif',
        fontSize: _selectedSize,
        fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
        height: 2.2,
        letterSpacing: 1.5,
        color: const Color(0xFF3E2723),
      );
    }
    return style;
  }

  Future<void> _handleAttachPhoto() async {
    final paymentRepo = ref.read(paymentRepositoryProvider);
    final isPremium = await paymentRepo.isPremium;
    final int maxPhotos = isPremium ? 3 : 1;
    
    if (_attachedPhotos.length >= maxPhotos) {
      if (!isPremium && _attachedPhotos.length == 1) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text('Nook Premium', style: TextStyle(color: AppTheme.accentGold, fontFamily: 'serif')),
              content: const Text('写真は1枚まで。複数枚の添付にはプレミアムプランの契約が必要です。', style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル', style: TextStyle(color: Colors.white38)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/store');
                  },
                  child: const Text('詳細を見る', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('添付できる写真は最大3枚までです')),
        );
        return;
      }
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    final newPhotoPath = image.path;
    
    String? caption;
    if (mounted) {
      final captionController = TextEditingController();
      caption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('写真に一言添える', style: TextStyle(color: AppTheme.accentGold, fontFamily: 'serif')),
          content: TextField(
            controller: captionController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: '写真についての思い出など...',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentGold)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, captionController.text),
              child: const Text('追加', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (caption == null && mounted) return;

    setState(() {
      _attachedPhotos.add(newPhotoPath);
      if (caption != null && caption.isNotEmpty) {
        _photoCaptions[newPhotoPath] = caption;
      }
    });
  }

  Future<void> _sendLetter() async {
    if (_toController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('宛名と本文を入力してください')),
      );
      return;
    }

    final daysDifference = _selectedDate.difference(DateTime.now()).inDays;
    if (daysDifference > 7) {
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final hasStamp = await paymentRepo.hasTimeCapsuleStamp;
      final isPremium = await paymentRepo.isPremium;
      
      if (!isPremium && !hasStamp) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text('特別な切手が必要です', style: TextStyle(color: AppTheme.accentGold, fontFamily: 'serif')),
              content: const Text('7日以上先の指定には、タイムカプセル切手、またはプレミアムプランの契約が必要です。', style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル', style: TextStyle(color: Colors.white38)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/store');
                  },
                  child: const Text('ストアを開く', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      DateTime? expiresAt;
      if (_selectedExpiration != '無制限') {
        final now = DateTime.now();
        switch (_selectedExpiration) {
          case '24時間':
            expiresAt = now.add(const Duration(hours: 24));
            break;
          case '7日間':
            expiresAt = now.add(const Duration(days: 7));
            break;
          case '30日間':
            expiresAt = now.add(const Duration(days: 30));
            break;
        }
      }

      final letter = Letter(
        toName: _toController.text,
        senderName: _senderController.text.isEmpty ? '名無し' : _senderController.text,
        content: _contentController.text,
        photoUrls: _attachedPhotos,
        themeId: 'default',
        fontFamily: _selectedFont,
        fontSize: _selectedSize,
        isBold: _isBold,
        unlockTime: _selectedDate,
        createdAt: DateTime.now(),
        envelopeType: _selectedEnvelope,
        paperType: _selectedPaper,
        photoCaptions: _photoCaptions,
        passcode: _passcodeEnabled ? _passcode : null,
        expiresAt: expiresAt,
      );

      final letterRepo = ref.read(letterRepositoryProvider);
      final letterId = await letterRepo.createLetter(letter);

      if (mounted) {
        final sharingService = ref.read(sharingServiceProvider);
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('手紙を封印しました', style: TextStyle(color: AppTheme.accentGold, fontFamily: 'serif')),
            content: const Text('この手紙への鍵を大切に相手へ届けましょう。', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/');
                },
                child: const Text('あとで', style: TextStyle(color: Colors.white38)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await sharingService.shareLetterUrl(letterId);
                  if (mounted) {
                    context.go('/home');
                  }
                },
                child: const Text('シェアして送る', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
              ),
            ],
          ),
        );

        // Show ad for free users
        ref.read(advertisementServiceProvider).showInterstitialAdIfNecessary(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('想いを綴る', style: TextStyle(fontFamily: 'serif', letterSpacing: 1.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, size: 28, color: AppTheme.accentGold),
            onPressed: _isLoading ? null : _sendLetter,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Row(
            children: [
              _buildTabButton(0, '本文を書く', Icons.edit_note),
              _buildTabButton(1, 'オプション', Icons.tune),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
          : IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildLetterTab(),
                _buildOptionsTab(),
              ],
            ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    bool isSelected = _currentTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.accentGold : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AppTheme.accentGold : Colors.white38, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120), // Extra bottom padding for toolbar
          child: Column(
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onLongPress: () {
              setState(() {
                _showFormattingToolbar = !_showFormattingToolbar;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_showFormattingToolbar ? '装飾バーを表示しました' : '装飾バーを非表示にしました'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                color: _getPaperColor(_selectedPaper),
                image: DecorationImage(
                  image: AssetImage(_getPaperAsset(_selectedPaper)),
                  fit: BoxFit.cover,
                  opacity: 1.0, 
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle luminosity layer for better text-to-background balance
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                    ),
                  ),
                  // Design Pattern Overlay
                  if (_selectedPaper == 'ポップ')
                    CustomPaint(
                      size: const Size(double.infinity, 500),
                      painter: _PopsPatternPainter(),
                    ),
                  if (_selectedPaper == 'ラブレター風')
                    CustomPaint(
                      size: const Size(double.infinity, 500),
                      painter: _LovePatternPainter(),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // Recipients
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 48, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _toController,
                          decoration: const InputDecoration(
                            hintText: '誰か',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            prefixText: 'To: ',
                            prefixStyle: TextStyle(color: Colors.black26),
                          ),
                          style: GoogleFonts.getFont(
                            _selectedFont,
                            fontSize: 16,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.black12, thickness: 0.5),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        style: _getContentStyle(),
                        decoration: InputDecoration(
                          hintText: 'あなたの想いを、ここに。',
                          hintStyle: _getContentStyle().copyWith(color: Colors.black12),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 32),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  // Sender
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Divider(color: Colors.black12, thickness: 0.5),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _senderController,
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(
                            hintText: 'あなた',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            prefixText: 'From: ',
                            prefixStyle: TextStyle(color: Colors.black26),
                          ),
                          style: GoogleFonts.getFont(
                            _selectedFont,
                            fontSize: 16,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                          onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
        if (_showFormattingToolbar)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _buildFormattingToolbar(),
          ),
      ],
    );
  }

  Widget _buildOptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildLetterOption(
                  label: '封印が解ける日',
                  value: '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                  icon: Icons.history_edu,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.dark(
                              primary: AppTheme.accentGold,
                              onPrimary: AppTheme.primaryDark,
                              surface: AppTheme.surfaceDark,
                              onSurface: AppTheme.textWhite,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
                const Divider(height: 48, color: Colors.white10),
                _buildLetterOption(
                  label: '封筒と便箋のデザイン',
                  value: '封筒: $_selectedEnvelope / 便箋: $_selectedPaper',
                  icon: Icons.mark_email_unread_outlined,
                  onTap: _showDesignSelector,
                ),
                const Divider(height: 48, color: Colors.white10),
                _buildLetterOption(
                  label: '同封する写真',
                  value: '${_attachedPhotos.where((p) => !p.contains('handwriting')).length}枚',
                  icon: Icons.photo_library_outlined,
                  onTap: _handleAttachPhoto,
                ),
                if (_attachedPhotos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPhotoList(),
                ],
                const Divider(height: 48, color: Colors.white10),
                _buildLetterOption(
                  label: '手書きを追加',
                  value: '指やペンで想いを描く',
                  icon: Icons.draw_outlined,
                  onTap: _showDrawingCanvas,
                ),
                const Divider(height: 48, color: Colors.white10),
                _buildSecuritySection(),
                const Divider(height: 48, color: Colors.white10),
                _buildExpirationSection(),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '※デザインの変更にはプレミアムプランまたは切手が必要です。',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _attachedPhotos.length,
        itemBuilder: (context, index) {
          final path = _attachedPhotos[index];
          final isHandwriting = path.contains('handwriting');
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    isHandwriting ? Icons.draw : Icons.photo,
                    color: Colors.white24,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _attachedPhotos.removeAt(index);
                        _photoCaptions.remove(path);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.architecture, color: AppTheme.accentGold, size: 20),
            const SizedBox(width: 12),
            _ToolbarAction(
              label: _selectedFont,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppTheme.surfaceDark,
                  builder: (context) => ListView(
                    shrinkWrap: true,
                    children: _fontOptions.map((f) => ListTile(
                      title: Text(f, style: GoogleFonts.getFont(f, color: Colors.white)),
                      onTap: () {
                        setState(() => _selectedFont = f);
                        Navigator.pop(context);
                      },
                    )).toList(),
                  ),
                );
              },
            ),
            const VerticalDivider(color: Colors.white24, indent: 15, endIndent: 15),
            _ToolbarAction(
              label: '${_selectedSize.toInt()} pt',
              onTap: () {
                setState(() {
                  if (_selectedSize == 18.0) _selectedSize = 22.0;
                  else if (_selectedSize == 22.0) _selectedSize = 14.0;
                  else _selectedSize = 18.0;
                });
              },
            ),
            const VerticalDivider(color: Colors.white24, indent: 15, endIndent: 15),
            IconButton(
              icon: Icon(Icons.format_bold, color: _isBold ? AppTheme.accentGold : Colors.white60),
              onPressed: () => setState(() => _isBold = !_isBold),
            ),
            const SizedBox(width: 24),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('WRITING TOOLS', style: TextStyle(color: AppTheme.accentGold, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text('$_selectedFont', style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterOption({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentGold.withOpacity(0.8), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 13, color: Colors.white38)),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_right, color: Colors.white24),
        ],
      ),
    );
  }

  Future<void> _showDesignSelector() async {
    final paymentRepo = ref.read(paymentRepositoryProvider);
    final isPremium = await paymentRepo.isPremium;
    final hasStamp = await paymentRepo.hasTimeCapsuleStamp;

    if (!isPremium && !hasStamp) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('デザインを変更するには', style: TextStyle(color: AppTheme.accentGold, fontFamily: 'serif')),
            content: const Text('プレミアムプランまたは有料の切手をお持ちの方のみ、特別な封筒や便箋をお選びいただけます。', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる', style: TextStyle(color: Colors.white38)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/store');
                },
                child: const Text('ストアへ', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('封筒と便箋を選ぶ', style: TextStyle(color: AppTheme.accentGold, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                const SizedBox(height: 12),
                const Text('プレミアムプランならすべてのデザインをご利用いただけます', style: TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 24),
                const Text('デザインを選択 (Envelope & Paper)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _designOptions.length,
                    itemBuilder: (context, index) {
                      final design = _designOptions[index];
                      final isLocked = !isPremium && !hasStamp && design != 'ノーマル';
                      final isSelected = _selectedEnvelope == design;
                      
                      return GestureDetector(
                        onTap: () {
                          if (isLocked) {
                            Navigator.pop(context);
                            _showDesignSelector(); // Re-trigger the lock dialog
                            return;
                          }
                          setModalState(() {
                            _selectedEnvelope = design;
                            _selectedPaper = design;
                          });
                          setState(() {
                            _selectedEnvelope = design;
                            _selectedPaper = design;
                          });
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? AppTheme.accentGold : Colors.white10,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.05),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getDesignColor(design),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getDesignIcon(design),
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    design,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (isLocked)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(Icons.lock, size: 16, color: AppTheme.accentGold.withOpacity(0.5)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('決定'),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Color _getDesignColor(String design) {
    switch (design) {
      case 'ポップ': return const Color(0xFFFFB3BA);
      case 'ラブレター風': return const Color(0xFFE57373);
      case '家族向け': return const Color(0xFFFFCC80);
      case '西洋風': return const Color(0xFFD7CCC8);
      case '和風': return const Color(0xFFC5E1A5);
      case '記念日': return const Color(0xFFFFD700);
      case '誕生日': return const Color(0xFFFFAB91);
      default: return AppTheme.primaryDark;
    }
  }

  IconData _getDesignIcon(String design) {
    switch (design) {
      case 'ポップ': return Icons.auto_awesome;
      case 'ラブレター風': return Icons.favorite;
      case '家族向け': return Icons.family_restroom;
      case '西洋風': return Icons.history_edu;
      case '和風': return Icons.filter_vintage;
      case '記念日': return Icons.auto_awesome;
      case '誕生日': return Icons.cake;
      default: return Icons.mail;
    }
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('閲覧パスコード', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('受取人が開く際に必要になります', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            Switch(
              value: _passcodeEnabled,
              onChanged: (value) => setState(() => _passcodeEnabled = value),
              activeColor: AppTheme.accentGold,
            ),
          ],
        ),
        if (_passcodeEnabled) ...[
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: const TextStyle(color: AppTheme.accentGold, letterSpacing: 8, fontSize: 20),
            decoration: const InputDecoration(
              hintText: '0000',
              hintStyle: TextStyle(color: Colors.white10),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.accentGold)),
              counterText: '',
            ),
            onChanged: (value) => _passcode = value,
          ),
        ],
      ],
    );
  }

  Widget _buildExpirationSection() {
    final options = ['無制限', '24時間', '7日間', '30日間'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('公開期限', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Text('期限を過ぎると手紙は自動的に消失します', style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedExpiration,
              dropdownColor: AppTheme.surfaceDark,
              isExpanded: true,
              items: options.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedExpiration = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getPaperAsset(String design) {
    switch (design) {
      case 'ポップ': return 'assets/images/pops_paper.png'; 
      case '家族向け': return 'assets/images/family_paper.png';
      case 'ラブレター風': return 'assets/images/love_letter_paper.png';
      case '西洋風': return 'assets/images/western_paper.png';
      case '和風': return 'assets/images/japanese_paper.png';
      case '記念日': return 'assets/images/anniversary_paper.png';
      case '誕生日': return 'assets/images/birthday_paper.png';
      default: return 'assets/images/human_paper_texture.png';
    }
  }

  Color _getPaperColor(String design) {
    switch (design) {
      case 'ポップ': return const Color(0xFFF0FCFF); // Lighter blueish/playful base
      case '家族向け': return const Color(0xFFFFF7E6);
      case 'ラブレター風': return const Color(0xFFFFEBEE); // Soft reddish base
      case '和風': return const Color(0xFFFAFAF0);
      case '西洋風': return const Color(0xFFFDFCF0);
      case '記念日': return const Color(0xFFFFF0F5);
      case '誕生日': return const Color(0xFFF0F8FF);
      default: return Colors.white;
    }
  }

  Color _getEnvelopeColor(String design) {
    switch (design) {
      case '和風': return const Color(0xFFE0E0D0);
      case '西洋風': return const Color(0xFFE8E4D8);
      case '記念日': return const Color(0xFFFFE0E0);
      case '誕生日': return const Color(0xFFE0F0FF);
      default: return const Color(0xFFF5F5F5);
    }
  }

  void _showDrawingCanvas() {
    List<Offset?> dialPoints = [];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFFAF6F0),
              insetPadding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    color: AppTheme.surfaceDark,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル', style: TextStyle(color: Colors.white38)),
                        ),
                        const Text('手書きで想いを添える', style: TextStyle(color: AppTheme.accentGold, fontFamily: 'serif', fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => setDialogState(() => dialPoints.clear()),
                          child: const Text('クリア', style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setDialogState(() {
                          dialPoints.add(details.localPosition);
                        });
                      },
                      onPanEnd: (details) {
                        setDialogState(() {
                          dialPoints.add(null);
                        });
                      },
                      child: CustomPaint(
                        painter: DrawingPainter(points: dialPoints),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: AppTheme.surfaceDark,
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _attachedPhotos.add('handwriting_path_${_attachedPhotos.length}.png');
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.primaryDark),
                      child: const Text('手紙に添える'),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ToolbarAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class RuledLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 1.0;

    const double lineSpacing = 18.0 * 2.2;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PopsPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF4DD0E1).withOpacity(0.15), // Teal
      const Color(0xFFFFD54F).withOpacity(0.15), // Yellow
      const Color(0xFFFF8A65).withOpacity(0.15), // Coral
    ];
    final random = math.Random(42);

    for (int i = 0; i < 40; i++) {
        final paint = Paint()..color = colors[random.nextInt(colors.length)];
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final radius = random.nextDouble() * 12 + 4;
        canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LovePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE57373).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    
    final random = math.Random(123);
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final scale = random.nextDouble() * 0.5 + 0.3;
      
      _drawSubtleHeart(canvas, Offset(x, y), scale, paint);
    }
  }

  void _drawSubtleHeart(Canvas canvas, Offset center, double scale, Paint paint) {
    final path = Path();
    final w = 40.0 * scale;
    final h = 40.0 * scale;
    
    path.moveTo(center.dx, center.dy + h * 0.3);
    path.cubicTo(center.dx - w * 0.5, center.dy - h * 0.2, center.dx - w, center.dy + h * 0.3, center.dx, center.dy + h);
    path.cubicTo(center.dx + w, center.dy + h * 0.3, center.dx + w * 0.5, center.dy - h * 0.2, center.dx, center.dy + h * 0.3);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
