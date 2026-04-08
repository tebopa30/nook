class Letter {
  final String? id;
  final String? senderUid;
  final String toName;
  final String senderName;
  final String content;
  final List<String> photoUrls;
  final String themeId;
  final String fontFamily;
  final double fontSize;
  final bool isBold;
  final DateTime unlockTime;
  final bool isOpened;
  final DateTime createdAt;
  final String envelopeType;
  final String paperType;
  final Map<String, String> photoCaptions;
  final String? passcode;    // Added for security
  final DateTime? expiresAt; // Added for expiration

  const Letter({
    this.id,
    this.senderUid,
    required this.toName,
    required this.senderName,
    required this.content,
    this.photoUrls = const [],
    required this.themeId,
    this.fontFamily = 'Shippori Mincho',
    this.fontSize = 18.0,
    this.isBold = false,
    required this.unlockTime,
    this.isOpened = false,
    required this.createdAt,
    this.envelopeType = 'normal',
    this.paperType = 'normal',
    this.photoCaptions = const {},
    this.passcode,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderUid': senderUid,
      'toName': toName,
      'senderName': senderName,
      'content': content,
      'photoUrls': photoUrls,
      'themeId': themeId,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'isBold': isBold,
      'unlockTime': unlockTime.toIso8601String(),
      'isOpened': isOpened,
      'createdAt': createdAt.toIso8601String(),
      'envelopeType': envelopeType,
      'paperType': paperType,
      'photoCaptions': photoCaptions,
      'passcode': passcode,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory Letter.fromJson(Map<String, dynamic> json, {String? id}) {
    return Letter(
      id: id,
      senderUid: json['senderUid'] as String?,
      toName: json['toName'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      themeId: json['themeId'] as String? ?? 'default',
      fontFamily: json['fontFamily'] as String? ?? 'Shippori Mincho',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
      isBold: json['isBold'] as bool? ?? false,
      unlockTime: DateTime.tryParse(json['unlockTime'] as String? ?? '') ?? DateTime.now(),
      isOpened: json['isOpened'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      envelopeType: json['envelopeType'] as String? ?? 'normal',
      paperType: json['paperType'] as String? ?? 'normal',
      photoCaptions: Map<String, String>.from(json['photoCaptions'] ?? {}),
      passcode: json['passcode'] as String?,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'] as String) : null,
    );
  }

  Letter copyWith({
    String? id,
    String? senderUid,
    String? toName,
    String? senderName,
    String? content,
    List<String>? photoUrls,
    String? themeId,
    String? fontFamily,
    double? fontSize,
    bool? isBold,
    DateTime? unlockTime,
    bool? isOpened,
    DateTime? createdAt,
    String? envelopeType,
    String? paperType,
    Map<String, String>? photoCaptions,
    String? passcode,
    DateTime? expiresAt,
  }) {
    return Letter(
      id: id ?? this.id,
      senderUid: senderUid ?? this.senderUid,
      toName: toName ?? this.toName,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      photoUrls: photoUrls ?? this.photoUrls,
      themeId: themeId ?? this.themeId,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      unlockTime: unlockTime ?? this.unlockTime,
      isOpened: isOpened ?? this.isOpened,
      createdAt: createdAt ?? this.createdAt,
      envelopeType: envelopeType ?? this.envelopeType,
      paperType: paperType ?? this.paperType,
      photoCaptions: photoCaptions ?? this.photoCaptions,
      passcode: passcode ?? this.passcode,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
