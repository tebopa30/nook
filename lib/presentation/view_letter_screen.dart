import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/letter_repository.dart';
import '../domain/letter.dart';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/utils/platform_web_utils.dart';
import 'dart:math' as math;

class ViewLetterScreen extends ConsumerStatefulWidget {
  final String letterId;

  const ViewLetterScreen({super.key, required this.letterId});

  @override
  ConsumerState<ViewLetterScreen> createState() => _ViewLetterScreenState();
}

class _ViewLetterScreenState extends ConsumerState<ViewLetterScreen> with TickerProviderStateMixin {
  Letter? _letter;
  bool _isLoading = true;
  bool _isOpened = false;
  bool _isBreakingWax = false;
  bool _isCracking = false;
  late AnimationController _shakeController;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 50));
    _loadLetter();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadLetter() async {
    final repo = ref.read(letterRepositoryProvider);
    
    try {
      final letter = await repo.getLetter(widget.letterId);
      
      if (mounted) {
        if (letter != null) {
          final now = DateTime.now();
          
          // Check for Expiration
          if (letter.expiresAt != null && now.isAfter(letter.expiresAt!)) {
            setState(() {
              _letter = null;
              _isLoading = false;
            });
            return;
          }

          _letter = letter;
          _isOpened = letter.isOpened;
          
          // Save to local inbox
          await repo.saveReceivedLetterId(widget.letterId);
          
          if (letter.unlockTime.isAfter(now)) {
            _remainingTime = letter.unlockTime.difference(now);
            _startTimer();
          }
        } else {
          _setupDummyLetter();
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _setupDummyLetter();
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupDummyLetter() {
    final isLocked = widget.letterId.contains('locked');
    _letter = Letter(
      id: widget.letterId,
      toName: 'あなた',
      senderName: 'Nook 開発チーム',
      content: '想いを届けるためのアプリ Nook をご利用いただきありがとうございます。\n\nすぐにメッセージが届く現代において、あえて時間をかけて、手紙を。そんな特別な体験を大切にしています。\n\nこの手紙が、あなたの日常に少しの安らぎをもたらしますように。',
      photoUrls: ['dummy_photo_1.jpg'],
      themeId: 'default',
      fontFamily: 'Shippori Mincho',
      fontSize: 18.0,
      unlockTime: isLocked ? DateTime.now().add(const Duration(minutes: 5)) : DateTime.now().subtract(const Duration(minutes: 5)),
      isOpened: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    _isOpened = _letter!.isOpened;
    
    final now = DateTime.now();
    if (_letter!.unlockTime.isAfter(now)) {
      _remainingTime = _letter!.unlockTime.difference(now);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_letter == null) return;
      
      final now = DateTime.now();
      if (_letter!.unlockTime.isAfter(now)) {
        if (mounted) {
          setState(() {
            _remainingTime = _letter!.unlockTime.difference(now);
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _remainingTime = Duration.zero;
          });
        }
      }
    });
  }

  Future<void> _openLetter() async {
    if (_letter == null || _isBreakingWax || _isCracking) return;
    
    // Check for Passcode
    if (_letter!.passcode != null && _letter!.passcode!.isNotEmpty) {
      final isCorrect = await _showPasscodeDialog();
      if (isCorrect != true) return;
    }

    if (mounted) {
      setState(() {
        _isCracking = true;
      });
    }
    
    // Stage 1: Tense Cracking
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isCracking = false;
        _isBreakingWax = true;
      });
    }
    
    // Stage 2: Moment of Impact & Shake
    HapticFeedback.vibrate();
    _triggerShake();
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() {
        _isOpened = true;
        _isBreakingWax = false;
      });
    }
    
    try {
      final repo = ref.read(letterRepositoryProvider);
      if (widget.letterId.isNotEmpty && !widget.letterId.contains('dummy')) {
        await repo.markAsOpened(widget.letterId);
      }
    } catch (_) {}
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0).then((_) {
      _shakeController.reverse().then((_) {
        _shakeController.forward(from: 0.0).then((_) {
          _shakeController.reverse();
        });
      });
    });
  }

  Future<bool?> _showPasscodeDialog() async {
    String input = '';
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('パスコードを入力', style: TextStyle(color: AppTheme.accentGold, fontFamily: 'serif')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('この手紙は保護されています。', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 24),
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              style: const TextStyle(color: AppTheme.accentGold, letterSpacing: 16, fontSize: 24),
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '****',
                hintStyle: TextStyle(color: Colors.white10),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentGold)),
                counterText: '',
              ),
              onChanged: (value) => input = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('戻る', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              if (input == _letter!.passcode) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('パスコードが正しくありません')),
                );
              }
            },
            child: const Text('確認', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAsImage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      RenderRepaintBoundary? boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // To ensure high quality, we use a higher pixel ratio
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        // Better way: trigger a real download
        // For now, let's use the most compatible way for this environment:
        downloadImageWeb(pngBytes, 'nook_letter_${widget.letterId}.png');
      } else {
        // On Mobile, you'd typically use a package like image_gallery_saver.
        // For now, we'll just show a placeholder or use share_plus if available.
        // Since our primary target for recipients is the web link, Web is priority.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像の保存はこのデバイスではWeb版でサポートされています')),
        );
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像の保存に失敗しました')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  TextStyle _getContentStyle() {
    if (_letter == null) return const TextStyle(color: Color(0xFF3E2723));
    
    TextStyle style;
    try {
      style = GoogleFonts.getFont(
        _letter!.fontFamily,
        fontSize: _letter!.fontSize,
        fontWeight: _letter!.isBold ? FontWeight.bold : FontWeight.normal,
        height: 2.2,
        letterSpacing: 1.5,
        color: const Color(0xFF3E2723),
      );
    } catch (_) {
      style = TextStyle(
        fontFamily: 'serif',
        fontSize: _letter!.fontSize,
        fontWeight: _letter!.isBold ? FontWeight.bold : FontWeight.normal,
        height: 2.2,
        letterSpacing: 1.5,
        color: const Color(0xFF3E2723),
      );
    }
    return style;
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = duration.inDays;
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (days > 0) {
      return '$days日 $hours時間$minutes分$seconds秒';
    }
    return '$hours:$minutes:$seconds';
  }

  Color _getEnvelopeColor(String type) {
    switch (type) {
      case 'ポップ': return const Color(0xFFFFB3BA);
      case 'ラブレター風': return const Color(0xFFE57373);
      case '家族向け': return const Color(0xFFFFCC80);
      case '西洋風': return const Color(0xFFD7CCC8);
      case '和風': return const Color(0xFFC5E1A5);
      case 'ノーマル':
      default:
        return AppTheme.primaryDark;
    }
  }

  Color _getPaperColor(String type) {
    switch (type) {
      case 'ポップ': return const Color(0xFFF0FCFF);
      case '家族向け': return const Color(0xFFFFF7E6);
      case 'ラブレター風': return const Color(0xFFFFEBEE);
      case '和風': return const Color(0xFFFAFAF0);
      case '西洋風': return const Color(0xFFFDFCF0);
      case '記念日': return const Color(0xFFFFF0F5);
      case '誕生日': return const Color(0xFFF0F8FF);
      default: return Colors.white;
    }
  }

  String _getPaperAsset(String design) {
    switch (design) {
      case 'ポップ': return 'assets/images/pops_paper.png'; 
      case '家族向け': return 'assets/images/family_paper.png';
      case 'ラブレター風': return 'assets/images/love_letter_paper.png';
      case '和風': return 'assets/images/japanese_paper.png';
      case '西洋風': return 'assets/images/western_paper.png';
      case '記念日': return 'assets/images/anniversary_paper.png';
      case '誕生日': return 'assets/images/birthday_paper.png';
      default: return 'assets/images/human_paper_texture.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Nook Letter', style: TextStyle(fontFamily: 'serif', letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentGold),
        actions: [
          if (_isOpened && _remainingTime <= Duration.zero)
            IconButton(
              icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentGold))
                : const Icon(Icons.download_rounded),
              onPressed: _saveAsImage,
              tooltip: '画像として保存',
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
          : _letter == null
              ? const Center(child: Text('手紙が見つかりませんでした'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final isLocked = _remainingTime > Duration.zero;

    if (isLocked) {
      return Container(
        decoration: const BoxDecoration(color: AppTheme.primaryDark),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mail_outline, size: 100, color: AppTheme.accentGold),
              const SizedBox(height: 32),
              const Text(
                '開封の時を待つ',
                style: TextStyle(color: Colors.white38, fontSize: 16, fontFamily: 'serif'),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDuration(_remainingTime),
                style: const TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '予定日時: ${_letter!.unlockTime.year}/${_letter!.unlockTime.month}/${_letter!.unlockTime.day} ${_letter!.unlockTime.hour.toString().padLeft(2, '0')}:${_letter!.unlockTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isOpened) {
      return _buildWaxSealScreen();
    }

    // Opened Letter View
    return RepaintBoundary(
      key: _boundaryKey,
      child: Container(
        decoration: BoxDecoration(
          color: _getPaperColor(_letter?.paperType ?? 'ノーマル'),
          image: DecorationImage(
            image: AssetImage(_getPaperAsset(_letter?.paperType ?? 'ノーマル')),
            fit: BoxFit.cover,
            opacity: 1.0, // High-fidelity texture at full opacity
          ),
        ),
        child: Stack(
          children: [
            // Subtler luminosity layer for better text-to-background balance
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
            if ((_letter?.paperType ?? 'ノーマル') == 'ポップ')
              CustomPaint(
                size: const Size(double.infinity, 500),
                painter: _PopsPatternPainter(),
              ),
            if ((_letter?.paperType ?? 'ノーマル') == 'ラブレター風')
              CustomPaint(
                size: const Size(double.infinity, 500),
                painter: _LovePatternPainter(),
              ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                children: [
                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      '${_letter!.toName} へ',
                      style: const TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        height: 1.5,
                        color: Color(0xFF3E2723),
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),
                  CustomPaint(
                    painter: RuledLinesPainter(lineCount: (_letter!.content.length / 10).toInt() + 20),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Text(
                        _letter!.content,
                        style: _getContentStyle(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_letter!.senderName} より',
                      style: const TextStyle(
                        fontSize: 20, 
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF3E2723),
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                  if (_letter!.photoUrls.isNotEmpty) ...[
                    const SizedBox(height: 100),
                    Container(
                      height: 1,
                      color: Colors.black.withOpacity(0.05),
                    ),
                    const SizedBox(height: 32),
                    const Text('同封されていた写真', style: TextStyle(color: Colors.black26, fontSize: 13, fontFamily: 'serif')),
                    const SizedBox(height: 24),
                    ..._letter!.photoUrls.map((url) {
                      final caption = _letter!.photoCaptions[url];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 48.0),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 240,
                                  color: Colors.black.withOpacity(0.02),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(url.contains('handwriting') ? Icons.draw : Icons.photo_outlined, color: Colors.black12, size: 48),
                                        const SizedBox(height: 12),
                                        Text(url.contains('handwriting') ? 'Handwriting' : 'Photo', style: const TextStyle(color: Colors.black12, fontFamily: 'serif')),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (caption != null && caption.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                caption,
                                style: const TextStyle(fontFamily: 'serif', fontSize: 15, color: Color(0xFF5D4037), fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 100),
                  Center(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5D4037),
                        side: const BorderSide(color: Colors.black12),
                      ),
                      child: const Text('文箱へ戻る'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaxSealScreen() {
    return Container(
      decoration: BoxDecoration(
        color: _getEnvelopeColor(_letter?.envelopeType ?? 'ノーマル'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80), // To balance the bottom text and AppBar
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final double shakeValue = (1.0 - _shakeController.value) * 10;
                return Transform.translate(
                  offset: Offset(shakeValue, 0),
                  child: GestureDetector(
                    onTap: _openLetter,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Envelope Shape
                        if (!_isBreakingWax)
                          Container(
                            width: 300,
                            height: 200,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: const AssetImage('assets/images/envelope_texture_premium.png'),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  _getEnvelopeColor(_letter?.envelopeType ?? 'ノーマル'),
                                  BlendMode.modulate,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 12))
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Envelope Flap visual
                                CustomPaint(
                                  size: const Size(300, 200),
                                  painter: EnvelopePainter(color: _getEnvelopeColor(_letter?.envelopeType ?? 'ノーマル')),
                                ),
                              ],
                            ),
                          ),
                        
                        // Burst Effect Back
                        // Subtle Shard Effect (Reduced and less flashy)
                        if (_isBreakingWax) ...[
                          ...List.generate(6, (index) => _BreakingFragment(index: index)),
                        ],
                        
                        // The Seal itself
                        AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: _isBreakingWax ? 1.5 : (_isCracking ? 1.1 : 1.0),
                          curve: _isCracking ? Curves.elasticIn : Curves.easeOut,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _isBreakingWax ? 0.0 : 1.0,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Wrapped in ClipOval to hide square background of asset
                                ClipOval(
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      image: const DecorationImage(
                                        image: AssetImage('assets/images/wax_seal_v2.png'),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                // Crack Overlay during Cracking Phase
                                if (_isCracking)
                                  CustomPaint(
                                    size: const Size(120, 120),
                                    painter: _WaxCrackPainter(),
                                  ),
                                
                                // Glossy Shine Overlay
                                if (!_isBreakingWax)
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        center: const Alignment(-0.3, -0.3),
                                        radius: 0.6,
                                        colors: [
                                          Colors.white.withOpacity(0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 64),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _isBreakingWax ? 0.0 : 1.0,
              child: const Text(
                'open',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                  letterSpacing: 4,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnvelopePainter extends CustomPainter {
  final Color color;
  EnvelopePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final path = Path();
    // Top flap shadows
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height / 2 + 2);
    path.lineTo(size.width, 0);
    
    // Side flap shadows
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2 - 2, size.height / 2);
    path.lineTo(size.width, size.height);

    canvas.drawPath(path, paint);

    // Subtle edge highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
      
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RuledLinesPainter extends CustomPainter {
  final int lineCount;
  RuledLinesPainter({required this.lineCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 1.0;

    const double lineSpacing = 18.0 * 2.2; // Match fontSize * height

    for (int i = 0; i < lineCount; i++) {
        final double y = i * lineSpacing;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BreakingFragment extends StatefulWidget {
  final int index;
  const _BreakingFragment({required this.index});

  @override
  State<_BreakingFragment> createState() => _BreakingFragmentState();
}

class _BreakingFragmentState extends State<_BreakingFragment> with SingleTickerProviderStateMixin {
  late AnimationController _fragmentController;
  late double _vx;
  late double _vy;
  late double _vr; // Rotation velocity
  late double _size;

  @override
  void initState() {
    super.initState();
    final angle = (widget.index / 12) * 2 * 3.14159 + (widget.index % 3 * 0.2);
    final speed = 300.0 + (widget.index % 5) * 100;
    
    _vx = speed * 1.5 * (widget.index % 2 == 0 ? 1 : -1) * (widget.index / 12);
    _vx = speed * 0.8 * (angle.floor() % 2 == 0 ? 1 : -1) * (widget.index % 4 + 1);
    // Simple enough random-like values based on index
    // Realistic gravity-bound shards
    _vx = 100 * (widget.index % 2 == 0 ? 0.5 : -0.5);
    _vy = -150 * (widget.index % 3 + 1);
    _vr = (widget.index % 2 + 0.5);
    _size = 15.0 + (widget.index % 3) * 10.0;

    _fragmentController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fragmentController.forward();
  }

  @override
  void dispose() {
    _fragmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fragmentController,
      builder: (context, child) {
        final t = _fragmentController.value;
        const gravity = 1500.0;
        
        final x = _vx * t;
        final y = _vy * t + 0.5 * gravity * t * t;
        final opacity = 1.0 - t;

        return Transform.translate(
          offset: Offset(x, y),
          child: Transform.rotate(
            angle: _vr * t * 6.28,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000), // Deeper red for realism
                  borderRadius: BorderRadius.circular(widget.index % 3 == 0 ? 4 : 20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



class _WaxCrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Center cracks
    path.moveTo(size.width / 2, size.height / 2);
    path.lineTo(size.width / 2 + 20, size.height / 2 - 25);
    path.moveTo(size.width / 2, size.height / 2);
    path.lineTo(size.width / 2 - 30, size.height / 2 + 10);
    path.moveTo(size.width / 2 - 5, size.height / 2 - 5);
    path.lineTo(size.width / 2 + 15, size.height / 2 + 30);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
