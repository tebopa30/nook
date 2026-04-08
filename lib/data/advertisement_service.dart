import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_repository.dart';

final advertisementServiceProvider = Provider((ref) {
  return AdvertisementService(ref);
});

class AdvertisementService {
  final Ref _ref;
  int _letterCount = 0;

  AdvertisementService(this._ref);

  Future<void> showInterstitialAdIfNecessary(BuildContext context) async {
    final paymentRepo = _ref.read(paymentRepositoryProvider);
    final isPremium = await paymentRepo.isPremium;

    if (isPremium) return;

    _letterCount++;

    if (_letterCount % 3 == 0) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black,
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: double.maxFinite,
              height: 400,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://via.placeholder.com/300x500?text=Premium+Ad+Placeholder'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'プレミアムプランなら広告なしで快適に。',
                        style: TextStyle(color: Colors.white, fontSize: 12, backgroundColor: Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }
}
