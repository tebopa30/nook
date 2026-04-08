import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

class PaymentRepository {
  // Replace with actual RevenueCat API keys
  static const String _appleApiKey = 'YOUR_APPLE_API_KEY';
  static const String _googleApiKey = 'YOUR_GOOGLE_API_KEY';
  
  static const String _premiumEntitlementId = 'premium'; // Nook Premium (Subscription)
  static const String _timeCapsuleEntitlementId = 'time_capsule_stamp'; // Time Capsule Stamp (Non-consumable or consumable based on setup)
  
  bool _isConfigured = false;
  bool _isPremiumSimulated = false; // Simulation for testing

  Future<void> init() async {
    if (_isConfigured) return;
    
    await Purchases.setLogLevel(LogLevel.debug); // Or info in production
    
    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_googleApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_appleApiKey);
    }
    
    if (configuration != null) {
      await Purchases.configure(configuration);
      _isConfigured = true;
    }
  }

  Future<bool> get isPremium async {
    // Return simulated status if configured
    if (_isPremiumSimulated) return true;
    
    if (!_isConfigured) await init();
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_premiumEntitlementId]?.isActive == true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  void togglePremiumSimulation(bool value) {
    _isPremiumSimulated = value;
  }
  
  Future<bool> get hasTimeCapsuleStamp async {
    if (!_isConfigured) await init();
    try {
      // Logic might depend on RevenueCat configuration. 
      // If it's a consumable, we might need a custom check or local decrement.
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_timeCapsuleEntitlementId]?.isActive == true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<List<Package>> getOfferings() async {
    if (!_isConfigured) await init();
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages;
      }
      return [];
    } on PlatformException catch (_) {
      return [];
    }
  }

  Future<bool> purchasePackage(Package package) async {
    if (!_isConfigured) await init();
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      // Determine if a relevant entitlement became active
      return customerInfo.entitlements.active.isNotEmpty;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (!_isConfigured) await init();
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[_premiumEntitlementId]?.isActive == true;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
